defmodule Grid do
  defstruct xmax: 0, ymax: 0, map: %{}

  def new(), do: %__MODULE__{}

  def get(grid, {x, y}) do
    Map.get(grid.map, {x, y})
  end

  def put(grid, {x, y}, tile) do
    xmax = max(grid.xmax, x)
    ymax = max(grid.ymax, y)
    map = Map.put(grid.map, {x, y}, tile)

    %{grid | xmax: xmax, ymax: ymax, map: map}
  end

  def render(grid, path) do
    for y <- 0..grid.ymax do
      for x <- 0..grid.xmax do
        case {get(grid, {x, y}), {x, y} in path} do
          {_, true} ->
            IO.write("O")

          {chr, _} ->
            IO.write(chr)
        end
      end

      IO.puts("")
    end
  end
end

defmodule Hiker do
  def navigate(grid) do
    initial = {0..grid.xmax |> Enum.find(&(Grid.get(grid, {&1, 0}) == ".")), 0}
    exit = {0..grid.xmax |> Enum.find(&(Grid.get(grid, {&1, grid.ymax}) == ".")), grid.ymax}

    visited = %{initial => 0}
    queue = [{0, {initial, {0, 1}, 0, MapSet.new([initial])}}]

    navigate(grid, exit, queue, visited)
  end

  def navigate(_grid, exit, [], visited) do
    visited[exit]
  end

  def navigate(grid, exit, [{_, {current, heading, steps, path}} | queue], visited) do
    IO.inspect(steps)

    if current == exit do
      if "-v" in System.argv() do
        IO.puts("Found exit #{visited[current]}")
        Grid.render(grid, path)
      end
    end

    {queue, visited} =
      for {neighbor, nheading} <- neighbors(grid, current, heading),
          neighbor not in path,
          distance = steps - 1,
          reduce: {queue, visited} do
        {queue, visited} ->
          visited = Map.update(visited, neighbor, distance, &min(&1, distance))

          queue =
            enqueue(queue, {neighbor, nheading, distance, MapSet.put(path, neighbor)}, distance)

          {queue, visited}
      end

    navigate(grid, exit, queue, visited)
  end

  def enqueue([{current, _} | _] = queue, value, weight) when weight <= current do
    [{weight, value} | queue]
  end

  def enqueue([head | tail], value, weight) do
    [head | enqueue(tail, value, weight)]
  end

  def enqueue([], value, weight) do
    [{weight, value}]
  end

  def neighbors(grid, {x, y}, {hx, hy}) do
    [
      {1, 0},
      {-1, 0},
      {0, 1},
      {0, -1}
    ]
    |> Enum.reject(fn {dx, dy} -> {dx, dy} == {-hx, -hy} end)
    |> Enum.flat_map(fn {dx, dy} ->
      {nx, ny} = {x + dx, y + dy}

      case Grid.get(grid, {nx, ny}) do
        "." ->
          [{{nx, ny}, {dx, dy}}]

        _ ->
          []
      end
    end)
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
    |> Enum.reduce(grid, fn
      {char, x}, grid when char in ["<", ">", "^", "v"] ->
        Grid.put(grid, {x, y}, ".")
      {char, x}, grid ->
        Grid.put(grid, {x, y}, char)
    end)
  end)

grid
|> Hiker.navigate()
|> IO.inspect() #= 6334
