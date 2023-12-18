IO.stream(:stdio, :line)
|> Stream.map(&String.trim/1)
|> Enum.reduce({[{0, 0}], {0, 0}, 0}, fn line, {vertices, {x, y}, length} ->
  [_dir, _count, color] = String.split(line, " ")
  <<"(#", count::binary-size(5), dir::binary-size(1), ")">> = color
  count = String.to_integer(count, 16)

  dir = Map.fetch!(%{
    "0" => "R",
    "1" => "D",
    "2" => "L",
    "3" => "U"
  }, dir)

  {dx, dy} = Map.fetch!(%{
    "U" => {0, -1},
    "D" => {0, 1},
    "L" => {-1, 0},
    "R" => {1, 0}
  }, dir)

  pos = {x + count * dx, y + count * dy}

  {[pos | vertices], pos, length + count}
end)
|> then(fn {vertices, _, length} ->
  vertices
  |> Enum.zip(Enum.drop(vertices, 1))
  |> Enum.reduce(0, fn {{x1, y1}, {x2, y2}}, acc ->
    acc + 0.5 * (y1 + y2) * (x1 - x2)
  end)
  |> Kernel.abs()
  |> IO.inspect()
  |> Kernel.+(length/2)
  |> Kernel.+(1)
end)
|> IO.inspect()
