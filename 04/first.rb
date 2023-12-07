puts(STDIN.each_line.reduce(0) do |sum, line|
  (_, line) = line.split(': ')
  (win, numbers) = line.strip.split(' | ')

  win = Set.new(win.split(' ').map(&:strip).map(&:to_i))

  numbers = numbers.split(' ').map(&:strip).map(&:to_i)

  sum + (2**(numbers.count { |n| win.include?(n) } - 1)).floor
end)
