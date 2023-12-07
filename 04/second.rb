cards = {}
max_index = 0

STDIN.each_line do |line|
  (id, line) = line.split(': ')
  (_, id) = id.split(' ')
  id = id.to_i
  cards[id] ||= 0
  cards[id] += 1
  max_index = id

  (win, numbers) = line.strip.split(' | ')
  win = Set.new(win.split(' ').map(&:strip).map(&:to_i))
  numbers = numbers.split(' ').map(&:strip).map(&:to_i)

  wins = numbers.count { |n| win.include?(n) }

  1.upto(wins) do |dindex|
    cards[id + dindex] ||= 0
    cards[id + dindex] += cards[id]
  end
end

puts((1..max_index).reduce(0) do |sum, index|
  sum + cards[index] || 0
end)
