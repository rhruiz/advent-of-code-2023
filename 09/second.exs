defmodule OASIS do
  def predict(list) do
    firsts = predict(list, [])

    Enum.reduce(firsts, 0, fn first, acc -> first - acc end)
  end

  defp predict(list, acc) do
    {all_zeros, diffs, first} =
      list
      |> Stream.zip(Stream.drop(list, 1))
      |> Enum.reduce({true, [], nil}, fn
        {a, b}, {all_zeros, diffs, nil} ->
          diff = b - a
          {all_zeros && (diff == 0), [diff | diffs], a}

        {a, b}, {all_zeros, diffs, first} ->
          diff = b - a
          {all_zeros && (diff == 0), [diff | diffs], first}
      end)

    case all_zeros do
      true -> [first | acc]
      false -> predict(Enum.reverse(diffs), [first | acc])
    end
  end
end

IO.stream(:stdio, :line)
|> Stream.map(&String.trim/1)
|> Stream.map(&String.split(&1, " "))
|> Stream.map(fn line -> Enum.map(line, &String.to_integer/1) end)
|> Stream.map(&OASIS.predict/1)
|> Enum.reduce(0, &+/2)
|> IO.inspect()
