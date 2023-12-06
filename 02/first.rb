limits = {
  "red" => 12,
  "green" => 13,
  "blue" => 14,
}

puts(STDIN.each_line.reduce(0) do |sum, line|
  (id, draws) = line.split(': ')
  id = id.split(' ').last.to_i

  draws = draws.split('; ')

  possible = draws.all? do |draw|
    draw.split(', ').all? do |color|
      (amount, color) = color.split(' ')
      amount.to_i <= limits[color]
    end
  end

  sum + (possible ? id : 0)
end)
