defmodule Parser do
  def parse("seeds: " <> seeds, state) do
    seeds =
      String.split(seeds, " ")
      |> Enum.map(&String.to_integer/1)
      |> Enum.chunk_every(2)
      |> Enum.map(fn [begining, size] -> {begining, begining + size - 1} end)

    %{state | seeds: seeds}
  end

  def parse("", state) do
    %{state | current_map: nil}
  end

  def parse(line, state) do
    if String.ends_with?(line, "map:") do
      current_map = String.split(line, " ") |> hd()

      %{state | current_map: current_map, maps: Map.put(state.maps, current_map, [])}
    else
      maps = Map.update!(state.maps, state.current_map, fn maps ->
        [dst, src, size] = String.split(line, " ") |> Enum.map(&String.to_integer/1)

        maps ++ [{src, dst - src, size}]
      end)

      %{state | maps: maps}
    end
  end
end

defmodule FinderMacro do
  defmacro __using__(_opts \\ []) do
    state =
      IO.stream(:stdio, :line)
      |> Stream.map(&String.trim/1)
      |> Enum.reduce(%{seeds: [], maps: %{}, current_map: nil}, &Parser.parse/2)

    [
      quote do
        def seeds(), do: unquote(state.seeds)
        def find(number, "location"), do: number
      end |
    Enum.flat_map(state.maps, fn {key, ranges} ->
      [type, "to", target_type] = String.split(key, "-")

      Enum.map(ranges, fn {src, delta, size} ->
        quote do
          def find(number, unquote(type)) when unquote(src) <= number and unquote(src + size) > number do
            find(number + unquote(delta), unquote(target_type))
          end
        end
      end)
      ++ [
        quote do
          def find(number, unquote(type)), do: find(number, unquote(target_type))
        end]
    end)]
  end
end

defmodule Finder do
  use FinderMacro
end

Finder.seeds()
|> Enum.map(fn {a, b} -> Range.new(a, b) end)
|> Stream.flat_map(&Enum.to_list/1)
|> Stream.map(fn seed -> Finder.find(seed, "seed") end)
|> Enum.min()
|> IO.inspect()
