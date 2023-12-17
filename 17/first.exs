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
end

defmodule Heatmap do
  def neighbors(grid, {x, y}, {hx, hy}, steps) do
    [
      {1, 0},
      {-1, 0},
      {0, 1},
      {0, -1}
    ]
    |> Enum.reject(fn {dx, dy} -> {dx, dy} == {-hx, -hy} end)
    |> Enum.flat_map(fn {dx, dy} ->
      {nx, ny} = {x + dx, y + dy}
      same_heading = {hx, hy} == {dx, dy}

      case {Grid.get(grid, {nx, ny}), same_heading, steps} do
        {nil, _, _} ->
          []

        {_, true, 3} ->
          []

        {heat, true, steps} ->
          [{{nx, ny}, heat, {dx, dy}, steps + 1}]

        {heat, false, _steps} ->
          [{{nx, ny}, heat, {dx, dy}, 1}]
      end
    end)
  end

  def navigate(grid, [{_, {current, heading, steps, path}} | queue], heatmap) do
    exit = {grid.xmax, grid.ymax}

    case current do
       ^exit ->
        heatmap[{current, heading, steps}]

      _ ->
        {queue, heatmap} =
          for {neighbor, nheat, nheading, nsteps} <- neighbors(grid, current, heading, steps),
              heat = heatmap[{current, heading, steps}] + nheat,
              heat < heatmap[{neighbor, nheading, nsteps}],
              reduce: {queue, heatmap} do
            {queue, heatmap} ->
              heatmap = Map.put(heatmap, {neighbor, nheading, nsteps}, heat)

              queue =
                enqueue(
                  queue,
                  {neighbor, nheading, nsteps, [{neighbor, nheading, nsteps} | path]},
                  heat
                )

              {queue, heatmap}
          end

        navigate(grid, queue, heatmap)
    end
  end

  defp enqueue([{current, _} | _] = queue, value, weight) when weight <= current do
    [{weight, value} | queue]
  end

  defp enqueue([head | tail], value, weight) do
    [head | enqueue(tail, value, weight)]
  end

  defp enqueue([], value, weight) do
    [{weight, value}]
  end
end

IO.stream(:stdio, :line)
|> Stream.map(&String.trim/1)
|> Stream.with_index()
|> Enum.reduce(Grid.new(), fn {line, y}, grid ->
  line
  |> String.graphemes()
  |> Enum.with_index()
  |> Enum.reduce(grid, fn {char, x}, grid ->
    Grid.put(grid, {x, y}, String.to_integer(char))
  end)
end)
|> then(fn grid ->
  pos = {0, 0}
  visited = %{{pos, {1, 0}, 0} => 0, {pos, {0, 1}, 0} => 0}
  queue = [
    {0, {pos, {1, 0}, 0, []}},
    {0, {pos, {0, 1}, 0, []}}
  ]

  Heatmap.navigate(grid, queue, visited)
end)
|> IO.inspect()
