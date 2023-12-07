defmodule CamelPoker do
  @cards [?A, ?K, ?Q, ?T, ?9, ?8, ?7, ?6, ?5, ?4, ?3, ?2, ?J]

  for {card, index} <- @cards |> Enum.reverse() |> Enum.with_index() do
    def strength(unquote(card)), do: unquote(index)
  end

  def type(hand) do
    frequencies = Enum.frequencies(hand)

    if Map.has_key?(frequencies, ?J) do
      case frequencies |> Enum.sort_by(fn {card, v} -> [-v, -strength(card)] end) do
        [{_, 5}] -> 6
        [{_, 4}, {_, 1}] -> 6
        [{_, 3}, {_, 2}] -> 6
        [{_, 3}, {_, 1}, {_, 1}] -> 5
        [{_, 2}, {?J, 2}, {_, 1}] -> 5
        [{_, 2}, {_, 2}, {?J, 1}] -> 4
        [{_, 2}, {_, 1}, {_, 1}, {_, 1}] -> 3
        [{_, 1}, {_, 1}, {_, 1}, {_, 1}, {_, 1}] -> 1
      end
    else
      case frequencies |> Enum.sort_by(fn {_, v} -> -v end) do
        [{_, 5}] -> 6
        [{_, 4}, {_, 1}] -> 5
        [{_, 3}, {_, 2}] -> 4
        [{_, 3}, {_, 1}, {_, 1}] -> 3
        [{_, 2}, {_, 2}, {_, 1}] -> 2
        [{_, 2}, {_, 1}, {_, 1}, {_, 1}] -> 1
        _ -> 0
      end
    end
  end

  def sort(a, b) do
    if type(a) != type(b) do
      type(a) <= type(b)
    else
      Enum.zip(a, b)
      |> Enum.find(fn {a, b} -> strength(a) != strength(b) end)
      |> then(fn {a, b} -> strength(a) <= strength(b) end)
    end
  end
end

IO.stream(:stdio, :line)
|> Stream.map(&String.split(String.trim(&1), " "))
|> Stream.map(fn [hand, bid] -> {hand |> to_charlist(), bid |> String.to_integer()} end)
|> Enum.sort_by(fn {hand, _} -> hand end, &CamelPoker.sort/2)
|> Enum.with_index(1)
|> Enum.reduce(0, fn {{_hand, bid}, rank}, win -> win + bid * rank end)
|> IO.inspect()
