hails =
  IO.stream(:stdio, :line)
  |> Stream.map(&String.trim/1)
  |> Stream.each(fn _ -> Process.put(:line_count, Process.get(:line_count, 0) + 1) end)
  |> Stream.map(fn line ->
    line = String.replace(line, " @ ", ", ")

    [sx, sy, sz, vx, vy, vz] =
      line
      |> String.replace(" @ ", ", ")
      |> String.split(", ")
      |> Enum.map(&(&1 |> String.trim() |> String.to_integer()))

    {{sx, sy, sz}, {vx, vy, vz}}
  end)
  |> Enum.into([])

# Vx(Syn - Syn+1) + Vy(Sxn+1 - Sxn) + Sx(Vyn+1 - Vyn) + Sy(Vxn - Vxn+1) =
#   Syn*Vxn - Sxn*Vyn - Syn+1*Vxn+1 + Sxn+1*Vyn+1

solve = fn hails, a, b ->
  matrix =
    hails
    |> Enum.zip(Enum.drop(hails, 1))
    |> Enum.take(4)
    |> Enum.with_index()
    |> Enum.into(%{}, fn {{hail1, hail2}, index} ->
      {s1, v1} = hail1
      {s2, v2} = hail2

      sa1 = s1 |> elem(a)
      sa2 = s2 |> elem(a)
      sb1 = s1 |> elem(b)
      sb2 = s2 |> elem(b)

      va1 = v1 |> elem(a)
      va2 = v2 |> elem(a)
      vb1 = v1 |> elem(b)
      vb2 = v2 |> elem(b)

      {index,
       %{
         0 => sb1 - sb2,
         1 => sa2 - sa1,
         2 => vb2 - vb1,
         3 => va1 - va2,
         4 => sb1 * va1 - sa1 * vb1 - sb2 * va2 + sa2 * vb2
       }}
    end)

  matrix =
    Enum.reduce(0..3, matrix, fn index, matrix ->
      pivot = matrix[index][index]

      matrix =
        update_in(matrix, [index], fn row ->
          Enum.into(row, %{}, fn {j, value} ->
            {j, value / pivot}
          end)
        end)

      for i <- 0..3, i > index, reduce: matrix do
        matrix ->
          pivot = matrix[i][index]

          update_in(matrix, [i], fn row ->
            Enum.into(row, %{}, fn {j, value} ->
              {j, value - pivot * matrix[index][j]}
            end)
          end)
      end
    end)

  matrix =
    Enum.reduce(3..1, matrix, fn index, matrix ->
      for i <- 3..0, i < index, reduce: matrix do
        matrix ->
          pivot = matrix[i][index]

          update_in(matrix, [i], fn row ->
            Enum.into(row, %{}, fn {j, value} ->
              {j, value - pivot * matrix[index][j]}
            end)
          end)
      end
    end)

  Enum.map(0..3, fn index -> round(matrix[index][4]) end)
end

[_vx, _vy, sx, sy] = solve.(hails, 0, 1)
[_vy, _vz, ^sy, sz] = solve.(hails, 1, 2)
[_vx_, _vx, ^sx, ^sz] = solve.(hails, 0, 2)

IO.puts(sx + sy + sz)
