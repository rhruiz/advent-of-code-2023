defmodule HASH do
  def hash(str) do
    str
    |> to_charlist()
    |> Enum.reduce(0, fn chr, acc ->
      (acc + chr) |> Kernel.*(17) |> rem(256)
    end)
  end
end

defmodule HASHMAP do
  def new() do
    Enum.into(0..255, %{}, fn key -> {key, {MapSet.new(), []}} end)
  end

  def focusing_power(hashmap) do
    for {box, {_set, list}} <- hashmap,
        {lens, index} <- Enum.with_index(list),
        reduce: 0 do
      power -> power + focusing_power(box, index, lens)
    end
  end

  defp focusing_power(box, index, {_label, focal_length}) do
    (box + 1) * (index + 1) * focal_length
  end

  def delete(hashmap, label) do
    Map.update!(hashmap, HASH.hash(label), fn {set, list} ->
      if label in set do
        {MapSet.delete(set, label), Enum.reject(list, &match?({^label, _}, &1))}
      else
        {set, list}
      end
    end)
  end

  def set(hashmap, label, focal_length) do
    Map.update!(hashmap, HASH.hash(label), fn {set, list} ->
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

  def put(str, hashmap) when is_binary(str) and is_map(hashmap) do
    put(hashmap, str)
  end

  def put(hashmap, str) do
    if String.ends_with?(str, "-") do
      delete(hashmap, String.slice(str, 0..-2))
    else
      [label, focal_length] = String.split(str, "=")
      set(hashmap, label, String.to_integer(focal_length))
    end
  end
end

IO.stream(:stdio, :line)
|> Stream.flat_map(&String.split(&1, ","))
|> Enum.reduce(HASHMAP.new(), &HASHMAP.put/2)
|> HASHMAP.focusing_power()
|> IO.inspect()
