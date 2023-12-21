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

  def get(%{xmax: xmax}, {x, _}) when x > xmax, do: "#"

  def get(%{ymax: ymax}, {_, y}) when y > ymax, do: "#"

  def get(grid, {x, y}) do
    Map.get(grid.data, {x, y})
  end
end

defmodule Walker do
  def walk(_grid, [], visited) do
    Enum.reduce(visited, 0, fn {_, steps}, acc ->
      if steps == 0, do: acc + 1, else: acc
    end)
  end

  def walk(grid, [{{x, y}, steps} | queue], visited) do
    visited = MapSet.put(visited, {{x, y}, steps})

    queue =
      for {nx, ny} <- neighbors(grid, {x, y}),
          steps > 0,
          {{nx, ny}, steps - 1} not in visited,
          reduce: queue do
        queue ->
          [{{nx, ny}, steps - 1} | queue]
      end

    walk(grid, queue, visited)
  end

  def neighbors(grid, {x, y}) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]
    |> Enum.filter(fn pos -> Grid.get(grid, pos) != "#" end)
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
        "." -> {grid, initial}
        "#" -> {Grid.put(grid, {x, y}, "#"), initial}
        "S" -> {grid, {x, y}}
      end
    end)
  end)

steps = if(grid.xmax > 20, do: 64, else: 6)

grid
|> Walker.walk([{initial, steps}], MapSet.new())
|> IO.inspect()
