defmodule Grid do
  defstruct max: {0, 0}, grid: %{}

  def new(), do: %Grid{}

  def put(grid, {x, y}, nil) do
    %{grid | grid: Map.delete(grid.grid, {x, y})}
  end

  def put(grid, {x, y}, value) do
    xmax = max(elem(grid.max, 0), x)
    ymax = max(elem(grid.max, 1), y)

    %{grid | max: {xmax, ymax}, grid: Map.put(grid.grid, {x, y}, value)}
  end

  def get(grid, {x, y}) do
    Map.get(grid.grid, {x, y})
  end

  def expand(grid, expansion) do
    grid
    |> expand_axis(0, 0, expansion)
    |> expand_axis(0, 1, expansion)
  end

  defp expand_axis(%Grid{max: {xmax, _}} = grid, pos, 0, _) when pos > xmax do
    grid
  end

  defp expand_axis(%Grid{max: {_, ymax}} = grid, pos, 1, _) when pos > ymax do
    grid
  end

  defp expand_axis(grid, pos, index, expansion) do
    non_empty =
      Enum.any?(grid, fn {position, value} ->
        elem(position, index) == pos && value != nil
      end)

    case non_empty do
      false ->
        Enum.reduce(grid, grid, fn {position, value}, grid ->
          if elem(position, index) > pos do
            new_position = put_elem(position, index, elem(position, index) + expansion - 1)

            grid
            |> put(position, nil)
            |> put(new_position, value)
          else
            grid
          end
        end)
        |> expand_axis(pos + expansion, index, expansion)

      true ->
        expand_axis(grid, pos + 1, index, expansion)
    end
  end

  def distances(%Grid{grid: map} = grid) do
    map
    |> Map.keys()
    |> Enum.reduce(MapSet.new(), fn coord, pairs ->
      for candidate <- Map.keys(map),
          candidate != coord,
          Grid.get(grid, coord) != nil,
          Grid.get(grid, candidate) != nil,
          reduce: pairs do
        pairs -> MapSet.put(pairs, MapSet.new([coord, candidate]))
      end
    end)
    |> Enum.reduce(0, fn pair, acc ->
      [{xa, ya}, {xb, yb}] = MapSet.to_list(pair)
      acc + abs(xa - xb) + abs(ya - yb)
    end)
  end

  def parse() do
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
