import Bitwise

defmodule Mirror do
  def find({map, rows, cols}) do
    find(map, map, rows, 0, 0, false)
    |> then(fn
      false -> false
      count -> count * 100
    end)
    ||
      (
        map
        |> transpose(rows, cols)
        |> then(fn map -> find(map, map, cols, 0, 0, false) end)
      )
  end

  def find(_og_map, _map, rows, center, _, _flipped) when center > rows + 1 do
    false
  end

  def find(og_map, map, rows, center, delta, flipped) do
    case {flipped, Map.get(map, center - delta), Map.get(map, center + delta + 1)} do
      {false, a, nil} when a != nil ->
        find(og_map, map, rows, center + 1, 0, false)

      {false, nil, b} when b != nil ->
        find(og_map, map, rows, center + 1, 0, false)

      {true, a, nil} when a != nil ->
        center + 1

      {true, nil, b} when b != nil ->
        center + 1

      {flipped, a, a} ->
        find(og_map, map, rows, center, delta + 1, flipped)

      {true, _, _} ->
        find(og_map, og_map, rows, center + 1, 0, false)

      {false, a, b} ->
        pow = :math.log2(bxor(a, b))

        case pow == Float.round(pow, 0) do
          false ->
            find(og_map, map, rows, center + 1, 0, flipped)
          true ->
            find(og_map, Map.put(map, center - delta, map[center + delta + 1]), rows, center, delta, true)
            # ||
            #   find(og_mag, Map.put(map, center + delta + 1, map[center - delta]), rows, center, delta, true)
        end
    end
  end

  defp transpose(list, rows, cols) do
    init = Stream.cycle([0]) |> Enum.take(cols)

    (0..(rows - 1))
    |> Enum.reduce(init, fn index, acc -> push_bits(acc, list[index], []) end)
    |> Enum.with_index()
    |> Enum.into(%{}, fn {value, key} -> {cols - key - 1, value} end)
  end

  defp push_bits(cols, line, acc)

  defp push_bits([], 0, acc), do: Enum.reverse(acc)

  defp push_bits([head | tail], number, acc) do
    push_bits(tail, number >>> 1, [head <<< 1 ||| (number &&& 1) | acc])
  end
end


defmodule Day12 do
  def run(stream) do
    stream
    |> Stream.transform(
      fn -> [] end,
      fn line, acc ->
        case line do
          "\n" -> {[Enum.reverse(acc)], []}
          line -> {[], [line | acc]}
        end
      end,
        fn acc -> {[Enum.reverse(acc)], []} end,
        fn _ -> :halt end
    )
    |> Stream.map(fn map ->
      Enum.reduce(map, {%{}, 0, 0}, fn line, {acc, rows, cols} ->
        {new_cols, bin} = to_bin().(line, {0, 0}, to_bin())

        {Map.put(acc, rows, bin), rows + 1, max(new_cols, cols)}
      end)
    end)
    |> Stream.map(&Mirror.find/1)
    |> Enum.reduce(0, &+/2)
  end

  def to_bin do
    fn
      <<>>, acc, _ ->
        acc

      <<".", tail::binary>>, {count, acc}, and_then ->
        and_then.(tail, {count + 1, acc <<< 1 ||| 0}, and_then)

      <<"#", tail::binary>>, {count, acc}, and_then ->
        and_then.(tail, {count + 1, acc <<< 1 ||| 1}, and_then)

      <<_::binary-size(1), tail::binary>>, acc, and_then ->
        and_then.(tail, acc, and_then)
    end
  end
end

IO.stream(:stdio, :line)
|> Day12.run()
|> IO.inspect()
