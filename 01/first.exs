IO.stream(:stdio, :line)
|> Stream.map(&to_charlist/1)
|> Stream.map(fn charlist ->
  charlist
  |> Enum.filter(fn char -> char in ?0..?9 end)
  |> Enum.reduce(nil, fn char, acc ->
    case acc do
      nil -> {char - ?0, nil}
      {first, _} -> {first, char - ?0}
    end
  end)
  |> then(fn
    {a, nil} -> a * 10 + a
    {a, b} -> a * 10 + b
  end)
end)
|> Enum.sum()
|> IO.puts()
