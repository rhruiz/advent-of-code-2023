defmodule HASH do
  def hash(str) do
    str
    |> to_charlist()
    |> Enum.reduce(0, fn chr, acc ->
      (acc + chr) |> Kernel.*(17) |> rem(256)
    end)
  end

  def operation(str) do
    if String.ends_with?(str, "-") do
      {:remove, String.slice(str, 0..-2)}
    else
      [label, focal_length] = String.split(str, "=")
      {:set, label, String.to_integer(focal_length)}
    end
  end

  def focusing_power(box, index, {_label, focal_length}) do
    (box + 1) * (index + 1) * focal_length
  end
end

buckets = Enum.into(0..255, %{}, fn key -> {key, {MapSet.new(), []}} end)

IO.stream(:stdio, :line)
|> Stream.flat_map(&String.split(&1, ","))
|> Enum.reduce(buckets, fn str, buckets ->
  case HASH.operation(str) do
    {:remove, label} ->
      Map.update!(buckets, HASH.hash(label), fn {set, list} ->
        if label in set do
          {MapSet.delete(set, label), Enum.reject(list, &match?({^label, _}, &1))}
        else
          {set, list}
        end
      end)

    {:set, label, focal_length} ->
      Map.update!(buckets, HASH.hash(label), fn {set, list} ->
        if label in set do
          {set,
           Enum.map(list, fn
             {^label, _} -> {label, focal_length}
             item -> item
           end)}
        else
          {MapSet.put(set, label), list ++ [{label, focal_length}]}
        end
      end)
  end
end)
|> Enum.reduce(0, fn {box, {_set, list}}, acc ->
  list
  |> Enum.with_index()
  |> Enum.reduce(acc, fn {lens, index}, acc ->
    acc + HASH.focusing_power(box, index, lens)
  end)
end)
|> IO.inspect()
