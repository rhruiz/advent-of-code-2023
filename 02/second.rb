puts(STDIN.each_line.map(&:strip).reduce(0) do |power, line|
  mins = {'red' => 0, 'green' => 0, 'blue' => 0}
  (_id, draws) = line.split(': ')

  draws.split('; ').each do |draw|
    draw.split(', ').each do |color|
      (amount, color) = color.split(' ')
      mins[color] = [mins[color], amount.to_i].max
    end
  end

  power + mins.values.reduce(:*)
end)

