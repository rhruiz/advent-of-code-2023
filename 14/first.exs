defmodule Grid do
  defstruct xmax: 0, ymax: 0, map: %{}

  def new, do: %Grid{}

  def put(grid, {x, y}, nil) do
    map = Map.delete(grid.map, {x, y})

    %{grid | map: map}
  end

  def put(grid, {x, y}, value) do
    xmax = max(grid.xmax, x)
    ymax = max(grid.ymax, y)
    map = Map.put(grid.map, {x, y}, value)

    %{grid | map: map, xmax: xmax, ymax: ymax}
  end

  def get(grid, {x, y}) do
    Map.get(grid.map, {x, y})
  end

  def load(grid, {x, y}) do
    case get(grid, {x, y}) do
      :O -> grid.ymax - y + 1
      _ -> 0
    end
  end

  def render(grid) do
    Enum.each(0..(grid.ymax), fn y ->
      Enum.each(0..(grid.xmax), fn x ->
        case get(grid, {x, y}) do
          :O -> IO.write("O")
          :"#" -> IO.write("#")
          _ -> IO.write(".")
        end
      end)

      IO.puts("")
    end)

    IO.puts("")

    grid
  end

  def tilt(grid) do
    Enum.reduce(0..grid.xmax, grid, fn x, grid ->
      Enum.reduce(0..grid.ymax, grid, fn y, grid ->
        case {y, get(grid, {x, y}), get(grid, {x, y + 1})} do
          {y, nil, :O} ->
            grid
            |> put({x, y}, :O)
            |> put({x, y + 1}, nil)

          _ ->
            grid
        end
      end)
    end)
  end

  def total_load(grid) do
    for y <- 0..grid.ymax, x <- 0..grid.xmax, reduce: 0 do
      total -> total + load(grid, {x, y})
    end
  end

  def tilt_all(grid) do
    new_grid = tilt(grid)

    case new_grid do
      ^grid -> grid
      _ -> tilt_all(new_grid)
    end
  end
end

IO.stream(:stdio, :line)
|> Stream.with_index()
|> Enum.reduce(Grid.new(), fn {line, y}, grid ->
  line
  |> String.trim()
  |> String.graphemes()
  |> Enum.with_index()
  |> Enum.reduce(grid, fn {cell, x}, grid ->
    case cell do
      "O" -> Grid.put(grid, {x, y}, :O)
      "#" -> Grid.put(grid, {x, y}, :"#")
      _ -> grid
    end
  end)
end)
|> Grid.tilt_all()
|> Grid.total_load()
|> IO.puts()
