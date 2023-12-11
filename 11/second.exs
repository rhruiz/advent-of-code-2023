defmodule Grid do
  defstruct xmax: 0, ymax: 0, grid: %{}

  @expansion 1000000

  def new(), do: %Grid{}

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

  def expand(grid) do
    grid
    |> expand_columns(0)
    |> expand_lines(0)
  end

  defp expand_columns(%Grid{xmax: xmax} = grid, x) when x > xmax do
    grid
  end

  defp expand_columns(grid, x) do
    non_empty =
      Enum.any?(grid, fn {{xc, _yc}, value} ->
        xc == x && value != nil
      end)

    case non_empty do
      false ->
        Enum.reduce(grid, grid, fn {{xc, yc}, value}, grid ->
          if xc > x do
            grid
            |> put({xc, yc}, nil)
            |> put({xc + @expansion - 1, yc}, value)
          else
            grid
          end
        end)
        |> expand_columns(x + @expansion)

      true ->
        expand_columns(grid, x + 1)
    end
  end

  defp expand_lines(%Grid{ymax: ymax} = grid, y) when y > ymax do
    grid
  end

  defp expand_lines(grid, y) do
    non_empty =
      Enum.any?(grid, fn {{_xc, yc}, value} ->
        yc == y && value != nil
      end)

    case non_empty do
      false ->
        Enum.reduce(grid, grid, fn {{xc, yc}, value}, grid ->
          if yc > y do
            grid
            |> put({xc, yc}, nil)
            |> put({xc, yc + @expansion - 1}, value)
          else
            grid
          end
        end)
        |> expand_lines(y + @expansion)

      true ->
        expand_lines(grid, y + 1)
    end
  end
end

defimpl Enumerable, for: Grid do
  def count(%Grid{grid: map}) do
    {:ok, map_size(map)}
  end

  def member?(%Grid{grid: map}, {key, value}) do
    {:ok, match?(%{^key => ^value}, map)}
  end

  def member?(_map, _other) do
    {:ok, false}
  end

  def slice(%Grid{grid: map}) do
    size = map_size(map)
    {:ok, size, &:maps.to_list/1}
  end

  def reduce(%Grid{grid: map}, acc, fun) do
    Enumerable.List.reduce(:maps.to_list(map), acc, fun)
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
