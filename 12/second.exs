defmodule Spring do
  def possibilities(springs, broken) do
    {value, _cache} = possibilities(springs, false, broken, %{})
    value
  end

  defp possibilities(<<>>, broken_left, [], cache) when broken_left == 0 or broken_left == false do
    {1, cache}
  end

  defp possibilities(<<>>, _, _, cache), do: {0, cache}

  defp possibilities(<<".", tail::binary>>, false, broken, cache) do
    possibilities(tail, false, broken, cache)
  end

  defp possibilities(<<".", tail::binary>>, 0, broken, cache) do
    possibilities(tail, false, broken, cache)
  end

  defp possibilities(<<".", _::binary>>, _, _, cache), do: {0, cache}

  defp possibilities(<<"#", _::binary>>, false, [], cache), do: {0, cache}
  defp possibilities(<<"#", _::binary>>, 0, _, cache), do: {0, cache}

  defp possibilities(<<"#", tail::binary>>, false, [bhead | btail], cache),
    do: possibilities(tail, bhead - 1, btail, cache)

  defp possibilities(<<"#", tail::binary>>, n, broken, cache),
    do: possibilities(tail, n - 1, broken, cache)

  defp possibilities(<<"?", tail::binary>>, broken_left, broken, cache) do
    {with_working, cache} = cached("." <> tail, broken_left, broken, cache)
    {with_broken, cache} = cached("#" <> tail, broken_left, broken, cache)

    {with_working + with_broken, cache}
  end

  defp cached(springs, broken_left, broken, cache) do
    if Map.has_key?(cache, {springs, broken_left, broken}) do
      {Map.get(cache, {springs, broken_left, broken}), cache}
    else
      {value, cache} = possibilities(springs, broken_left, broken, cache)
      {value, Map.put(cache, {springs, broken_left, broken}, value)}
    end
  end
end

IO.stream(:stdio, :line)
|> Enum.map(&String.trim/1)
|> Enum.map(fn line ->
  [springs, broken] = String.split(line, " ", trim: true)
  springs = Stream.cycle([springs]) |> Enum.take(5) |> Enum.join("?")
  broken = Stream.cycle([broken]) |> Enum.take(5) |> Enum.join(",")

  broken = broken |> String.split(",", trim: true) |> Enum.map(&String.to_integer/1)

  {springs, broken}
end)
|> Enum.reduce(0, fn {springs, broken}, acc ->
  acc + Spring.possibilities(springs, broken)
end)
|> IO.inspect()
