edges =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Enum.flat_map(fn line ->
    [from, to] = String.split(line, ": ")
    to = String.split(to, " ")

    Enum.map(to, fn to -> MapSet.new([from, to]) end)
  end)
  |> Enum.into(MapSet.new())

if "--graph" in System.argv() do
  IO.puts("graph {")

  Enum.each(edges, fn pair ->
    [a, b] = MapSet.to_list(pair)
    IO.puts("  #{a} -- #{b}")
  end)

  IO.puts("}")
  System.halt(0)
end

# cat sample.txt | elixir first.exs --graph | neato -Tpng > sample.png
# cat input.txt | elixir first.exs --graph | neato -Tpng > input.png
to_cut =
  if MapSet.size(edges) > 15 do
    [
      ["mxd", "glz"],
      ["brd", "clb"],
      ["bbz", "jxd"]
    ]
  else
    [
      ["hfx", "pzl"],
      ["bvb", "cmg"],
      ["nvd", "jqt"]
    ]
  end

roots = to_cut |> hd()

edges =
  for pair <- to_cut,
      reduce: edges do
    edges -> MapSet.delete(edges, MapSet.new(pair))
  end

index =
  for pair <- edges,
      [a, b] = MapSet.to_list(pair),
      reduce: %{} do
    index ->
      index
      |> Map.put_new(a, MapSet.new())
      |> Map.put_new(b, MapSet.new())
      |> Map.update!(a, &MapSet.put(&1, b))
      |> Map.update!(b, &MapSet.put(&1, a))
  end

count = fn
  [], acc, _ ->
    MapSet.size(acc)

  [head | tail], acc, and_then ->
    if head in acc do
      and_then.(tail, acc, and_then)
    else
      next = MapSet.to_list(index[head])

      and_then.(next ++ tail, MapSet.put(acc, head), and_then)
    end
end

roots
|> Enum.map(fn root -> count.([root], MapSet.new(), count) end)
|> Enum.reduce(&Kernel.*/2)
|> IO.inspect()
