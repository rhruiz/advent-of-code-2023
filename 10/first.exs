defmodule Pipe do
  def vpipe(:up), do: :down
  def vpipe(:down), do: :up
  def vpipe(_), do: false

  def hpipe(:left), do: :right
  def hpipe(:right), do: :left
  def hpipe(_), do: false

  def l(:up), do: :right
  def l(:right), do: :up
  def l(_), do: false

  def j(:up), do: :left
  def j(:left), do: :up
  def j(_), do: false

  def seven(:down), do: :left
  def seven(:left), do: :down
  def seven(_), do: false

  def f(:down), do: :right
  def f(:right), do: :down
  def f(_), do: false

  def new("|") do
    &__MODULE__.vpipe/1
  end

  def new("-") do
    &__MODULE__.hpipe/1
  end

  def new("L") do
    &__MODULE__.l/1
  end

  def new("J") do
    &__MODULE__.j/1
  end

  def new("7") do
    &__MODULE__.seven/1
  end

  def new("F") do
    &__MODULE__.f/1
  end
end

defmodule Grid do
  defstruct xmax: 0, ymax: 0, grid: %{}

  def new() do
    %Grid{}
  end

  def put(grid, {x, y}, value) do
    xmax = max(grid.xmax, x)
    ymax = max(grid.ymax, y)

    %Grid{xmax: xmax, ymax: ymax, grid: Map.put(grid.grid, {x, y}, value)}
  end

  def get(grid, {x, y}) do
    Map.get(grid.grid, {x, y})
  end
end

{grid, {xs, ys}} =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.with_index()
  |> Enum.reduce({Grid.new(), nil}, fn {line, y}, {grid, start} ->
    line
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce({grid, start}, fn {char, x}, {grid, start} ->
      case char do
        "." -> {grid, start}
        "S" -> {Grid.put(grid, {x, y}, "S"), {x, y}}
        _ -> {Grid.put(grid, {x, y}, Pipe.new(char)), start}
      end
    end)
  end)

delta_to_entrance = %{
  {0, 1} => :up,
  {0, -1} => :down,
  {1, 0} => :left,
  {-1, 0} => :right
}

direction_to_delta = %{
  :up => {0, -1},
  :down => {0, 1},
  :left => {-1, 0},
  :right => {1, 0}
}

s_type = Enum.find(~W(| - L J 7 F), fn type ->
  Enum.any?(~W(up down left right)a, fn dir ->
    if Pipe.new(type).(dir) == false do
      false
    else
      {dx, dy} = direction_to_delta[dir]
      neighbour = Grid.get(grid, {xs + dx, ys + dy})
      onther_dir = Pipe.new(type).(dir)
      {odx, ody} = direction_to_delta[onther_dir]
      other_neighbour = Grid.get(grid, {xs + odx, ys + ody})

      neighbour != nil && neighbour.(delta_to_entrance[{dx, dy}]) != false &&
        other_neighbour != nil && other_neighbour.(delta_to_entrance[{odx, ody}]) != false
    end
  end)
end)

new_grid = Grid.put(grid, {xs, ys}, Pipe.new(s_type))

dir = Enum.find(~W(up down left right)a, fn dir ->
  Grid.get(new_grid, {xs, ys}).(dir) != false
end)

{dx, dy} = direction_to_delta[dir]
dir = delta_to_entrance[{dx, dy}]

sim = fn
  steps, {^xs, ^ys}, _, _ ->
    steps

  steps, {x, y}, direction, and_then ->
    exit = Grid.get(new_grid, {x, y}).(direction)

    {dx, dy} = direction_to_delta[exit]

    and_then.(steps + 1, {x + dx, y + dy}, delta_to_entrance[{dx, dy}], and_then)
end

sim.(1, {xs + dx, ys + dy}, dir, sim)
|> div(2)
|> IO.inspect()
