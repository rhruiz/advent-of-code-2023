defmodule HASH do
  def hash(str) do
    str
    |> to_charlist()
    |> Enum.reduce(0, fn chr, acc ->
      (acc + chr) |> Kernel.*(17) |> rem(256)
    end)
  end
end

IO.stream(:stdio, :line)
|> Stream.flat_map(&String.split(&1, ","))
|> Stream.map(&HASH.hash/1)
|> Enum.reduce(0, &(&1 + &2))
|> IO.inspect()
