defmodule Grid do
  defstruct xmax: 0, ymax: 0, data: %{}

  def new() do
    %Grid{}
  end

  def put(grid, {x, y}, value) do
    data = Map.put(grid.data, {x, y}, value)
    xmax = max(grid.xmax, x)
    ymax = max(grid.ymax, y)

    %{grid | data: data, xmax: xmax, ymax: ymax}
  end

  def get(grid, {x, y}) do
    Map.get(grid.data, {x, y})
  end
end

defmodule Walker do
  def walk(_grid, [], visited) do
    visited
  end

  def walk(grid, [{{x, y}, steps} | queue], visited) do
    case Map.fetch(visited, {x, y}) do
      {:ok, _} ->
        walk(grid, queue, visited)

      :error ->
        visited = Map.put(visited, {x, y}, steps)

        queue =
          for {nx, ny} <- neighbors(grid, {x, y}),
              !Map.has_key?(visited, {nx, ny}),
              reduce: queue do
            queue ->
              queue ++ [{{nx, ny}, steps + 1}]
          end

        walk(grid, queue, visited)
    end
  end

  def neighbors(grid, {x, y}) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]
    |> Enum.filter(fn pos -> Grid.get(grid, pos) == "." end)
  end
end

{grid, initial} =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.with_index()
  |> Enum.reduce({Grid.new(), nil}, fn {line, y}, {grid, initial} ->
    line
    |> String.graphemes()
    |> Stream.with_index()
    |> Enum.reduce({grid, initial}, fn {char, x}, {grid, initial} ->
      case char do
        "." -> {Grid.put(grid, {x, y}, "."), initial}
        "#" -> {grid, initial}
        "S" -> {Grid.put(grid, {x, y}, "."), {x, y}}
      end
    end)
  end)

tiles = Walker.walk(grid, [{initial, 0}], %{})

tiles
|> Enum.count(fn {_, steps} -> steps <= 64 && Integer.mod(steps, 2) == 0 end)
|> IO.inspect()

n = div(26_501_365 - div(grid.xmax + 1, 2), grid.xmax + 1)
IO.inspect(n)

even_corners = Enum.count(tiles, fn {_, steps} -> Integer.mod(steps, 2) == 0 && steps > 65 end)
odd_corners = Enum.count(tiles, fn {_, steps} -> Integer.mod(steps, 2) == 1 && steps > 65 end)

even_full = Enum.count(tiles, fn {_, steps} -> Integer.mod(steps, 2) == 0 end)
odd_full = Enum.count(tiles, fn {_, steps} -> Integer.mod(steps, 2) == 1 end)

even = n * n
odd = (n + 1) * (n + 1)

IO.inspect({even_corners, odd_corners, even_full, odd_full, even, odd})

(odd * odd_full + even * even_full - (n + 1) * odd_corners + n * even_corners)
# 612941134797232
|> IO.inspect(label: "612941134797232 == ")
