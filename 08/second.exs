instructions = IO.stream(:stdio, :line) |> Enum.take(1) |> hd |> String.trim() |> to_charlist()
_ = IO.stream(:stdio, :line) |> Enum.take(1)

{nodes, starting_nodes} =
  IO.stream(:stdio, :line)
  |> Enum.reduce({%{}, []}, fn line, {nodes, starting_nodes} ->
    <<name::binary-size(3), " = (", left::binary-size(3), ", ", right::binary-size(3), _::binary>> =
      line

    starting_nodes =
      case name do
        <<_::binary-size(2), "A">> -> [name | starting_nodes]
        _ -> starting_nodes
      end

    {Map.put(nodes, name, {left, right}), starting_nodes}
  end)


starting_nodes
|> Enum.map(fn node ->
  instructions
  |> Stream.cycle()
  |> Stream.with_index(1)
  |> Stream.transform(node, fn {instruction, steps}, node ->
    {left, right} = Map.get(nodes, node)

    new_node = case instruction do
      ?L -> left
      ?R -> right
    end

    {[{new_node, steps}], new_node}
  end)
  |> Enum.find(&match?({<<_::binary-size(2), "Z">>, _}, &1))
  |> elem(1)
end)
|> Enum.reduce(fn a, b -> div(a * b, Integer.gcd(a, b)) end)
|> IO.inspect()
