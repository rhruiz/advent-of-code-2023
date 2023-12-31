IO.stream(:stdio, :line)
|> Stream.map(&String.trim/1)
|> Stream.map(&String.split(&1, ":", trim: true))
|> Stream.map(&Enum.drop(&1, 1))
|> Stream.map(&Enum.map(&1, fn str -> str |> String.replace(" ", "") |>  String.to_integer() end))
|> Stream.zip()
|> Enum.map(fn {tmax, rec} ->
  [
    div(tmax + floor(:math.sqrt(tmax*tmax - 4*rec)), 2),
    div(tmax - ceil(:math.sqrt(tmax*tmax - 4*rec)), 2)
  ]
  |> then(fn xs ->
    [min, max] = Enum.sort(xs)

    beat_the_record = fn t -> -t*t + tmax*t > rec end

    min =
      min
      |> Stream.unfold(fn i -> {i, i + 1} end)
      |> Enum.find(beat_the_record)

    max =
      max
      |> Stream.unfold(fn i -> {i, i - 1} end)
      |> Enum.find(beat_the_record)

    max - min + 1
  end)
end)
|> IO.inspect(charlists: :as_lists)
|> Enum.reduce(1, &(&1 * &2))
|> IO.inspect()
