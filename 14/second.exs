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

  def apply_delta({x, y}, {dx, dy}), do: {x + dx, y + dy}

  def tilt(grid, {dx, dy}) do
    {rangea, rangeb, {indexa, indexb}} = case {dx, dy} do
      {0, 1} -> {grid.ymax..0, grid.xmax..0, {1, 0}}
      {0, -1} -> {grid.ymax..0, grid.xmax..0, {1, 0}}
      {1, 0} -> {0..grid.xmax, 0..grid.ymax, {0, 1}}
      {-1, 0} -> {grid.xmax..0, grid.ymax..0, {0, 1}}
    end

    Enum.reduce(rangea, grid, fn a, grid ->
      Enum.reduce(rangeb, grid, fn b, grid ->
        coord = {a, b}
                |> put_elem(indexa, a)
                |> put_elem(indexb, b)

        next_coord = apply_delta(coord, {dx, dy})

        case {get(grid, coord), get(grid, next_coord)} do
          {nil, :O} ->
            grid
            |> put(coord, :O)
            |> put(next_coord, nil)

          _ ->
            grid
        end
      end)
    end)
  end

  def cycle(grid) do
    grid
    |> tilt_all({0, 1})
    |> tilt_all({1, 0})
    |> tilt_all({0, -1})
    |> tilt_all({-1, 0})
  end

  def cycle_all(grid) do
    cycle_all(grid, 0)
  end

  def cycle_all(grid, count) do
    new_grid = cycle(grid)

    IO.inspect({count, total_load(grid)})

    case new_grid do
      ^grid -> count
      _ -> cycle_all(new_grid, count + 1)
    end
  end

  def total_load(grid) do
    for y <- 0..grid.ymax, x <- 0..grid.xmax, reduce: 0 do
      total -> total + load(grid, {x, y})
    end
  end

  def tilt_all(grid, delta) do
    new_grid = tilt(grid, delta)

    case new_grid do
      ^grid -> grid
      _ -> tilt_all(new_grid, delta)
    end
  end
end

grid =
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

Stream.unfold({0, grid}, fn {count, grid} ->
  load = Grid.total_load(grid)
  {{count, load}, {count + 1, Grid.cycle(grid)}}
end)
|> Stream.each(&IO.inspect/1)
|> Stream.take(200)
|> Stream.run()

# {168, 94302}
# {169, 94283}
# {170, 94269}
# {171, 94258}
# {172, 94253}
# {173, 94245}
# {174, 94255}
# {175, 94263}
# {176, 94278}
# {177, 94295}
# {178, 94312}
# {179, 94313}
# {180, 94315}
# {181, 94309}

# 168 -> 0
# 181 -> 13
# 1000000000 - 168 -> 999999832
# (1000000000 - 168) % 14 -> 6
# 168 + 6 -> 174
# 174 = 94255
