defmodule Parser do
  def parse("seeds: " <> seeds, state) do
    %{state | seeds: String.split(seeds, " ") |> Enum.map(&String.to_integer/1)}
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

defmodule Finder do
  def find(_state, number, "location"), do: number

  def find(state, number, type) do
    key = Enum.find(Map.keys(state.maps), fn key ->
      String.starts_with?(key, "#{type}-to-")
    end)

    [^type, "to", target_type] = String.split(key, "-")

    target_number = Enum.find_value(state.maps[key], number, fn {src, delta, size} ->
      if src <= number && src + size >= number do
        number + delta
      else
        false
      end
    end)

    find(state, target_number, target_type)
  end
end

state =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Enum.reduce(%{seeds: [], maps: %{}, current_map: nil}, &Parser.parse/2)

state.seeds
|> Enum.map(fn seed -> Finder.find(state, seed, "seed") end)
|> Enum.min()
|> IO.inspect()
