Code.compile_file("grid.ex")

Grid.parse() |> Grid.expand(1000000) |> Grid.distances() |> IO.inspect()
