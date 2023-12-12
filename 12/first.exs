defmodule Spring do
  def possibilities(springs, broken) do
    frequencies = Enum.frequencies(springs)
    variables = frequencies["?"] || 0

    Enum.count(0..(Integer.pow(2, variables) - 1), fn i ->
      candidate = replace(springs, i, [])

      broken ==
        candidate
        |> Enum.chunk_by(fn chr -> chr == "#" end)
        |> Enum.flat_map(fn x ->
          case Enum.count(x, fn chr -> chr == "#" end) do
            0 -> []
            count -> [count]
          end
        end)
    end)
  end

  defp replace([], _, acc) do
    Enum.reverse(acc)
  end

  defp replace(["?" | tail], bin, acc) do
    import Bitwise

    case bin &&& 1 do
      0 -> replace(tail, bin >>> 1, ["." | acc])
      1 -> replace(tail, bin >>> 1, ["#" | acc])
    end
  end

  defp replace([head | tail], possibility, acc) do
    replace(tail, possibility, [head | acc])
  end
end

IO.stream(:stdio, :line)
|> Enum.map(&String.trim/1)
|> Enum.map(fn line ->
  [springs, broken] = String.split(line, " ", trim: true)
  broken = broken |> String.split(",", trim: true) |> Enum.map(&String.to_integer/1)
  springs = springs |> String.graphemes()

  {springs, broken}
end)
|> Enum.reduce(0, fn {springs, broken}, acc ->
  acc + Spring.possibilities(springs, broken)
end)
|> IO.inspect()
