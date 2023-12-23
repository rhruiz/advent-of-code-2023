defmodule Mavity do
  def move(bricks, space) do
    move(bricks, space, [])
  end

  def move([], space, acc) do
    {Brick.sort(acc), space}
  end

  def move([{brick, index} | tail], space, acc) do
    blocks = Brick.blocks(down(brick))

    occupied = Enum.any?(blocks, &occupied?(space, &1, index))

    case occupied do
      true ->
        move(tail, space, [{brick, index} | acc])

      false ->
        space =
          blocks
          |> Enum.reduce(space, fn {x, y, z}, space ->
            space
            |> Map.update(z + 1, %{}, &Map.delete(&1, {x, y}))
            |> Map.put_new(z, %{})
            |> put_in([z, {x, y}], index)
          end)

        move(enqueue(tail, {down(brick), index}), space, acc)
    end
  end

  def down({{xa, ya, za}, {xb, yb, zb}}) do
    {{xa, ya, za - 1}, {xb, yb, zb - 1}}
  end

  def up({{xa, ya, za}, {xb, yb, zb}}) do
    {{xa, ya, za + 1}, {xb, yb, zb + 1}}
  end

  def occupied?(_space, {_, _, 0}, _index), do: true

  def occupied?(space, {x, y, z}, index) do
    value = get_in(space, [z, {x, y}])

    value != nil && value != index
  end

  defp enqueue([], current) do
    [current]
  end

  defp enqueue([head | tail] = queue, current) do
    {{{_, _, zsa}, {_, _, zsb}}, _} = head
    {{{_, _, za}, {_, _, zb}}, _} = current

    case min(za, zb) < min(zsa, zsb) do
      true -> [current | queue]
      false -> [head | enqueue(tail, current)]
    end
  end
end

defmodule Brick do
  def blocks({{xa, ya, za}, {xb, yb, zb}}) do
    for x <- xa..xb, y <- ya..yb, z <- za..zb, do: {x, y, z}
  end

  def sort(bricks) do
    bricks
    |> Enum.sort(fn {{{_, _, za}, {_, _, zb}}, _}, {{{_, _, zc}, {_, _, zd}}, _} ->
      min(za, zb) < min(zc, zd)
    end)
  end
end

bricks =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.map(fn line ->
    [from, to] =
      line
      |> String.split("~")
      |> Enum.map(fn line ->
        line |> String.split(",") |> Enum.map(&String.to_integer/1) |> List.to_tuple()
      end)

    {from, to}
  end)
  |> Enum.with_index()
  |> Brick.sort()

space =
  for {brick, index} <- bricks,
      {x, y, z} <- Brick.blocks(brick),
      reduce: %{} do
    space -> Map.update(space, z, %{{x, y} => index}, &Map.put(&1, {x, y}, index))
  end

{bricks, space} = Mavity.move(bricks, space)

bricks_by_index = Enum.into(bricks, %{}, fn {brick, index} -> {index, brick} end)

Enum.count(bricks, fn {brick, index} ->
  up_bricks =
    brick
    |> Mavity.up()
    |> Brick.blocks()
    |> Enum.flat_map(fn {x, y, z} ->
      other_brick = get_in(space, [z, {x, y}])

      if other_brick != nil && other_brick != index do
        [other_brick]
      else
        []
      end
    end)
    |> Enum.uniq()

  if List.first(up_bricks) == nil do
    true
  else
    Enum.all?(up_bricks, fn other ->
      bricks_by_index
      |> Map.get(other)
      |> Brick.blocks()
      |> Enum.any?(fn {x, y, z} ->
        other_supporting_brick = get_in(space, [z - 1, {x, y}])
        if other_supporting_brick != index && other_supporting_brick != nil && other_supporting_brick != other do
          true
        else
          false
        end
      end)
    end)
  end
end)
|> IO.inspect()
