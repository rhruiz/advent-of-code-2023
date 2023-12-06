defmodule Parser do
  def x(line) do
    x(line, nil)
  end

  def x(line, nil) do
    {first, rest} = parse(false, line)
    x(rest, {first, nil})
  end

  def x(line, {first, digit}) do
    case parse(true, line) do
      nil -> {first, digit}
      {digit, rest} -> x(rest, {first, digit})
    end
  end

  defp parse(has_first, line)

  defp parse(true, "oneight" <> rest), do: parse(true, "eight" <> rest)
  defp parse(true, "twone" <> rest), do: parse(true, "one" <> rest)
  defp parse(true, "threeight" <> rest), do: parse(true, "eight" <> rest)
  defp parse(true, "fiveight" <> rest), do: parse(true, "eight" <> rest)
  defp parse(true, "sevenine" <> rest), do: parse(true, "nine" <> rest)
  defp parse(true, "eightwo" <> rest), do: parse(true, "two" <> rest)
  defp parse(true, "eighthree" <> rest), do: parse(true, "three" <> rest)
  defp parse(true, "nineight" <> rest), do: parse(true, "eight" <> rest)

  defp parse(_, "one" <> rest), do: {1, rest}
  defp parse(_, "two" <> rest), do: {2, rest}
  defp parse(_, "three" <> rest), do: {3, rest}
  defp parse(_, "four" <> rest), do: {4, rest}
  defp parse(_, "five" <> rest), do: {5, rest}
  defp parse(_, "six" <> rest), do: {6, rest}
  defp parse(_, "seven" <> rest), do: {7, rest}
  defp parse(_, "eight" <> rest), do: {8, rest}
  defp parse(_, "nine" <> rest), do: {9, rest}
  defp parse(_, "0" <> rest), do: {0, rest}
  defp parse(_, "1" <> rest), do: {1, rest}
  defp parse(_, "2" <> rest), do: {2, rest}
  defp parse(_, "3" <> rest), do: {3, rest}
  defp parse(_, "4" <> rest), do: {4, rest}
  defp parse(_, "5" <> rest), do: {5, rest}
  defp parse(_, "6" <> rest), do: {6, rest}
  defp parse(_, "7" <> rest), do: {7, rest}
  defp parse(_, "8" <> rest), do: {8, rest}
  defp parse(_, "9" <> rest), do: {9, rest}
  defp parse(_, ""), do: nil
  defp parse(first, <<_::8, rest::binary>>), do: parse(first, rest)
end

IO.stream(:stdio, :line)
|> Stream.map(fn line ->
  line
  |> String.trim()
  |> Parser.x()
  |> IO.inspect()
  |> then(fn
    {a, nil} -> a * 10 + a
    {a, b} -> a * 10 + b
  end)
end)
|> Enum.sum()
|> IO.inspect()
