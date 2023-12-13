import Bitwise

to_bin = fn
  <<>>, acc, _ ->
    acc

  <<".", tail::binary>>, {count, acc}, and_then ->
    and_then.(tail, {count + 1, acc <<< 1 ||| 0}, and_then)

  <<"#", tail::binary>>, {count, acc}, and_then ->
    and_then.(tail, {count + 1, acc <<< 1 ||| 1}, and_then)

  <<_::binary-size(1), tail::binary>>, acc, and_then ->
    and_then.(tail, acc, and_then)
end

defmodule Mirror do
  def find(map) do
    cols = Enum.max_by(map, &elem(&1, 0)) |> elem(0)

    map = Enum.map(map, &elem(&1, 1))

    map
    |> Enum.zip(Enum.drop(map, 1))
    |> find([])
    |> then(fn
      false -> false
      count -> count * 100
    end)
    ||
      (
        transposed = transpose(map, cols)

        transposed
        |> Enum.zip(Enum.drop(transposed, 1))
        |> find([])
      )
  end

  defp find(list, acc)

  defp find([], _acc) do
    false
  end

  defp find([{a, a} | tail], acc) do
    found =
      tail
      |> Enum.zip(acc)
      |> Enum.all?(&match?({{_, a}, a}, &1))

    case found do
      true -> length(acc) + 1
      false -> find(tail, [a | acc])
    end
  end

  defp find([{a, _b} | tail], acc) do
    find(tail, [a | acc])
  end

  defp transpose(list, cols) do
    init = Stream.cycle([0]) |> Enum.take(cols)

    list
    |> Enum.reduce(init, fn i, acc -> push_bits(acc, i, []) end)
    |> Enum.reverse()
  end

  defp push_bits(cols, line, acc)

  defp push_bits([], 0, acc), do: Enum.reverse(acc)

  defp push_bits([head | tail], number, acc) do
    push_bits(tail, number >>> 1, [head <<< 1 ||| (number &&& 1) | acc])
  end
end

IO.stream(:stdio, :line)
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
|> Stream.map(fn map -> Enum.map(map, &to_bin.(&1, {0, 0}, to_bin)) end)
|> Stream.map(&Mirror.find/1)
|> Enum.reduce(0, &+/2)
|> IO.inspect()
