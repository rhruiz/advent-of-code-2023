defmodule Grid do
  defstruct xmax: 0, ymax: 0, map: %{}, beams: %{}

  def new(), do: %__MODULE__{}

  def energized(grid) do
    grid.beams |> map_size()
  end

  def render(grid) do
    for y <- 0..grid.ymax do
      for x <- 0..grid.xmax do
        case Map.get(grid.beams, {x, y}) do
          nil -> "."
          energy -> "#{energy}"
        end
      end
      |> Enum.join()
      |> IO.puts()
    end

    IO.puts("")

    grid
  end

  def get(grid, {x, y}) do
    Map.get(grid.map, {x, y})
  end

  def add_beam(grid, {x, y}) do
    beams = Map.update(grid.beams, {x, y}, 1, fn beams -> beams + 1 end)

    %{grid | beams: beams}
  end

  def put(grid, {x, y}, tile) do
    xmax = max(grid.xmax, x)
    ymax = max(grid.ymax, y)
    map = Map.put(grid.map, {x, y}, tile)

    %{grid | xmax: xmax, ymax: ymax, map: map}
  end
end

defmodule Empty do
  @behaviour Tile
  def intercept(beam), do: [beam]
end

defmodule Slash do
  # > /
  def intercept({1, 0}), do: [{0, -1}]

  # / <
  def intercept({-1, 0}), do: [{0, 1}]

  # v
  # /
  def intercept({0, 1}), do: [{-1, 0}]

  # /
  # ^
  def intercept({0, -1}), do: [{1, 0}]
end

defmodule Backslash do
  # > \
  def intercept({1, 0}), do: [{0, 1}]

  # \ <
  def intercept({-1, 0}), do: [{0, -1}]

  # \
  # ^
  def intercept({0, -1}), do: [{-1, 0}]

  # v
  # \
  def intercept({0, 1}), do: [{1, 0}]
end

defmodule VerticalPipe do
  # v
  # |
  def intercept({0, 1}), do: [{0, 1}]

  # |
  # ^
  def intercept({0, -1}), do: [{0, -1}]

  # > |
  def intercept({1, 0}), do: [{0, 1}, {0, -1}]

  # | <
  def intercept({-1, 0}), do: [{0, 1}, {0, -1}]
end

defmodule HorizontalPipe do
  # >-
  def intercept({1, 0}), do: [{1, 0}]

  # -<
  def intercept({-1, 0}), do: [{-1, 0}]

  # v
  # -
  def intercept({0, 1}), do: [{1, 0}, {-1, 0}]

  # -
  # ^
  def intercept({0, -1}), do: [{1, 0}, {-1, 0}]
end

defmodule Tile do
  @type beam :: {integer(), integer()}
  @callback intercept(beam()) :: [beam()]

  def parse(char) do
    case char do
      "." -> Empty
      "/" -> Slash
      "\\" -> Backslash
      "|" -> VerticalPipe
      "-" -> HorizontalPipe
    end
  end
end

defmodule Simulator do
  @empty :queue.new()

  def simulate(grid, @empty, _), do: grid

  def simulate(grid, queue, visited) do
    {{:value, {beam, position}}, queue} = :queue.out(queue)

    {x, y} = position

    case {Grid.get(grid, position), {beam, position} in visited} do
      {nil, _} ->
        simulate(grid, queue, visited)

      {_tile, true} ->
        simulate(grid, queue, visited)

      {tile, false} ->
        new_queue =
          beam
          |> tile.intercept()
          |> Enum.reduce(queue, fn {dx, dy} = new_beam, queue ->
            :queue.in({new_beam, {x + dx, y + dy}}, queue)
          end)

        grid
        |> Grid.add_beam(position)
        |> simulate(new_queue, MapSet.put(visited, {beam, position}))
    end
  end
end

grid =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.with_index()
  |> Enum.reduce(Grid.new(), fn {line, y}, grid ->
    line
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce(grid, fn {char, x}, grid ->
      Grid.put(grid, {x, y}, Tile.parse(char))
    end)
  end)

[
  0..grid.ymax |> Enum.map(fn y -> [{{1, 0}, {0, y}}, {{-1, 0}, {grid.xmax, y}}] end),
  0..grid.xmax |> Enum.map(fn x -> [{{0, 1}, {x, 0}}, {{0, -1}, {x, grid.ymax}}] end)
]
|> List.flatten()
|> Enum.map(fn {beam, position} ->
  queue = :queue.from_list([{beam, position}])

  grid
  |> Simulator.simulate(queue, MapSet.new())
  |> Grid.energized()
end)
|> Enum.max()
|> IO.inspect()
