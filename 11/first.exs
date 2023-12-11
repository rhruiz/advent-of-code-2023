Code.compile_file("grid.ex")

Grid.parse() |> Grid.expand(2) |> Grid.distances() |> IO.inspect()

