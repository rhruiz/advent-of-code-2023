vx = fn {_, {vx, _, _}} -> vx end
vy = fn {_, {_, vy, _}} -> vy end

to_line = fn {{sx, sy, _}, {vx, vy, _}} ->
  {vy / vx, sy - sx * vy / vx}
end

intersects = fn {a, c}, {b, d} ->
  {(d - c) / (a - b), a * (d - c) / (a - b) + c}
end

time = fn {{sx, _, _}, {vx, _, _}}, x ->
  (x - sx) / vx
end

IO.stream(:stdio, :line)
|> Stream.map(&String.trim/1)
|> Stream.each(fn _ -> Process.put(:line_count, Process.get(:line_count, 0) + 1) end)
|> Stream.map(fn line ->
  [s, v] = String.split(line, " @ ")

  [sx, sy, sz] = String.split(s, ", ") |> Enum.map(&(&1 |> String.trim() |> String.to_integer()))
  [vx, vy, vz] = String.split(v, ", ") |> Enum.map(&(&1 |> String.trim() |> String.to_integer()))

  {{sx, sy, sz}, {vx, vy, vz}}
end)
|> Enum.into([])
|> then(fn lines ->
  Stream.flat_map(lines, fn line ->
    for pair <- lines,
        pair != line,
        vy.(line) / vx.(line) != vy.(pair) / vx.(pair) do
      MapSet.new([line, pair])
    end
  end)
end)
|> Stream.uniq()
|> Stream.map(&MapSet.to_list/1)
|> Stream.flat_map(fn [left, right] ->
  {x, y} = intersects.(to_line.(left), to_line.(right))

  if time.(left, x) >= 0 && time.(right, x) >= 0 do
    [{x, y}]
  else
    []
  end
end)
|> Stream.filter(fn {x, y} ->
  {low, high} =
    if(Process.get(:line_count, 0) > 10,
      do: {200_000_000_000_000, 400_000_000_000_000},
      else: {7, 27}
    )

  x >= low && x <= high && y >= low && y <= high
end)
|> Enum.into([])
|> Enum.count()
|> IO.inspect()
