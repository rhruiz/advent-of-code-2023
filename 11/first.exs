defmodule Grid do
  defstruct xmax: 0, ymax: 0, grid: %{}

  def new() do
    %Grid{}
  end

  def put(grid, {x, y}, nil) do
    %{grid | grid: Map.delete(grid.grid, {x, y})}
  end

  def put(grid, {x, y}, value) do
    xmax = max(grid.xmax, x)
    ymax = max(grid.ymax, y)

    %{grid | xmax: xmax, ymax: ymax, grid: Map.put(grid.grid, {x, y}, value)}
  end

  def get(grid, {x, y}) do
    Map.get(grid.grid, {x, y})
  end

  def render(grid) do
    for y <- 0..grid.ymax do
      for x <- 0..grid.xmax do
        case get(grid, {x, y}) do
          nil -> "."
          value -> to_string(value)
        end
      end
      |> Enum.join()
      |> IO.puts()
    end
  end

  def expand(grid) do
    grid
    |> expand_columns(0)
    |> expand_lines(0)
  end

  defp expand_columns(%Grid{xmax: xmax} = grid, x) when x > xmax do
    grid
  end

  defp expand_columns(grid, x) do
    all_empty =
      Enum.all?(0..grid.ymax, fn y ->
        get(grid, {x, y}) == nil
      end)

    case all_empty do
      true ->
        Enum.reduce(grid.xmax..x, grid, fn x, grid ->
          Enum.reduce(0..grid.ymax, grid, fn y, grid ->
            put(grid, {x + 1, y}, get(grid, {x, y}))
          end)
        end)
        |> then(fn grid ->
          Enum.reduce(0..grid.ymax, grid, fn y, grid ->
            put(grid, {x, y}, nil)
          end)
        end)
        |> expand_columns(x + 2)

      false ->
        expand_columns(grid, x + 1)
    end
  end

  defp expand_lines(%Grid{ymax: ymax} = grid, y) when y > ymax do
    grid
  end

  defp expand_lines(grid, y) do
    all_empty =
      Enum.all?(0..grid.xmax, fn x ->
        get(grid, {x, y}) == nil
      end)

    case all_empty do
      true ->
        Enum.reduce(grid.ymax..y, grid, fn y, grid ->
          Enum.reduce(0..grid.xmax, grid, fn x, grid ->
            put(grid, {x, y + 1}, get(grid, {x, y}))
          end)
        end)
        |> then(fn grid ->
          Enum.reduce(0..grid.xmax, grid, fn x, grid ->
            put(grid, {x, y}, nil)
          end)
        end)
        |> expand_lines(y + 2)

      false ->
        expand_lines(grid, y + 1)
    end
  end
end

grid =
  IO.stream(:stdio, :line)
  |> Stream.with_index()
  |> Enum.reduce({Grid.new(), 0}, fn {line, y}, {grid, id} ->
    line
    |> String.trim()
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce({grid, id}, fn {char, x}, {grid, id} ->
      case char do
        "." -> {grid, id}
        "#" -> {Grid.put(grid, {x, y}, id), id + 1}
      end
    end)
  end)
  |> elem(0)
  |> Grid.expand()

pairs =
  Enum.reduce(Map.keys(grid.grid), MapSet.new(), fn coord, pairs ->
    for candidate <- Map.keys(grid.grid),
        Grid.get(grid, coord) != nil,
        Grid.get(grid, candidate) != nil,
        candidate != coord,
        reduce: pairs do
      pairs -> MapSet.put(pairs, MapSet.new([coord, candidate]))
    end
  end)

pairs
|> Enum.reduce(0, fn pair, acc ->
  [{xa, ya}, {xb, yb}] = MapSet.to_list(pair)
  acc + abs(xa - xb) + abs(ya - yb)
end)
|> IO.inspect()
