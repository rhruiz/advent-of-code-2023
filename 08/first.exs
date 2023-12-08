instructions = IO.stream(:stdio, :line) |> Enum.take(1) |> hd |> String.trim() |> to_charlist()
_ = IO.stream(:stdio, :line) |> Enum.take(1)

nodes = IO.stream(:stdio, :line) |> Enum.reduce(%{}, fn line, nodes ->
  <<name::binary-size(3), " = (", left::binary-size(3), ", ", right::binary-size(3), _::binary>> = line

  Map.put(nodes, name, {left, right})
end)

instructions
|> Stream.cycle()
|> Stream.with_index(1)
|> Stream.transform("AAA", fn {instruction, steps}, node ->
  {left, right} = Map.get(nodes, node)

  new_node = case instruction do
    ?L -> left
    ?R -> right
  end

  {[{new_node, steps}], new_node}
end)
|> Enum.find(fn {node, _steps} -> node == "ZZZ" end)
|> then(fn {_node, steps} -> IO.puts(steps) end)
