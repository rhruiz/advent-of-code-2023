criteria =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.take_while(&(&1 != ""))
  |> Enum.into(%{}, fn line ->
    [name, body] = String.split(line, "{")
    [body | _] = String.split(body, "}")

    name = String.to_atom(name)

    tests =
      body
      |> String.split(",")
      |> Enum.map(fn
        "A" ->
          :A

        "R" ->
          :R

        <<rule::binary-size(2)>> ->
          {:rule, String.to_atom(rule)}

        <<rule::binary-size(3)>> ->
          {:rule, String.to_atom(rule)}

        test ->
          [<<category::binary-size(1), op::binary-size(1), right::binary>>, destination] =
            String.split(test, ":")

          {:if, String.to_atom(category), String.to_atom(op), String.to_integer(right),
           String.to_atom(destination)}
      end)

    {name, tests}
  end)

defmodule AcceptTree do
  def build(nodes, [test | tail]) do
    case test do
      :R ->
        :R

      :A ->
        :A

      {:if, category, op, right, destination} ->
        {{category, op, right}, build(nodes, tail),
         build(nodes, nodes[destination] || [destination])}

      {:rule, rule} ->
        build(nodes, nodes[rule])
    end
  end

  def reverse({category, :<, right}), do: {category, :>=, right}
  def reverse({category, :>, right}), do: {category, :<=, right}
  def reverse({category, :>=, right}), do: {category, :<, right}
  def reverse({category, :<=, right}), do: {category, :>, right}

  def accepted_pathes(tree) do
    accepted_pathes([], tree, [])
  end

  def accepted_pathes(pathes, tree, acc)

  def accepted_pathes(pathes, :A, acc) do
    [acc | pathes]
  end

  def accepted_pathes(pathes, :R, _acc) do
    pathes
  end

  def accepted_pathes(pathes, {cond, left, right}, acc) do
    pathes
    |> accepted_pathes(left, [reverse(cond) | acc])
    |> accepted_pathes(right, [cond | acc])
  end
end

init = ~w[x m a s]a |> Enum.into(%{}, fn k -> {k, {1, 4000}} end)

criteria
|> AcceptTree.build(criteria[:in])
|> AcceptTree.accepted_pathes()
|> Enum.map(fn rules ->
  Enum.reduce(rules, init, fn
    {category, :>, right}, init ->
      {min, max} = Map.get(init, category)
      Map.put(init, category, {max(min, right + 1), max})

    {category, :<, right}, init ->
      {min, max} = Map.get(init, category)
      Map.put(init, category, {min, min(max, right - 1)})

    {category, :<=, right}, init ->
      {min, max} = Map.get(init, category)
      Map.put(init, category, {min, min(max, right)})

    {category, :>=, right}, init ->
      {min, max} = Map.get(init, category)
      Map.put(init, category, {max(min, right), max})
  end)
end)
|> Enum.reduce(0, fn init, acc ->
  init
  |> Map.values()
  |> Enum.reduce(1, fn {min, max}, acc -> acc * (max - min + 1) end)
  |> Kernel.+(acc)
end)
|> IO.inspect()
