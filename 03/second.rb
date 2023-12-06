class Grid
  def initialize
    @grid = {}
    @xmax = 0
    @ymax = 0
  end

  attr_reader :xmax, :ymax

  def [](x, y)
    @grid[[x, y]]
  end

  def []=(x, y, value)
    @xmax = x if x > @xmax
    @ymax = y if y > @ymax
    @grid[[x, y]] = value
  end

  def inspect
    @grid.inspect
  end
end


grid = STDIN.each_line.each_with_index.reduce(Grid.new) do |grid, (line, y)|
  line.strip.split('').each_with_index.reduce(grid) do |grid, (char, x)|
    grid[x, y] = char if char != '.'
    grid
  end
end

number_pos = Set.new
numbers = Set.new

(0..grid.ymax).each do |y|
  (0..grid.xmax).each do |x|
    if grid[x, y] && !(grid[x, y] in ('0'..'9'))
      (-1..1).each do |dx|
        (-1..1).each do |dy|
          next if dx == 0 and dy == 0

          if grid[x + dx, y + dy] in ('0'..'9')
            number_pos << [[x + dx, y + dy], [x, y]]
          end
        end
      end
    end
  end
end

number_pos.each do |((x, y), origin)|
  current = [grid[x, y]]
  start = [x, y]

  (x-1).downto(0).each do |xc|
    if grid[xc, y] in ('0'..'9')
      start = [xc, y]
      current.unshift(grid[xc, y])
    else
      break
    end
  end

  ((x+1)..(grid.xmax)).each do |xc|
    if grid[xc, y] in ('0'..'9')
      current << grid[xc, y]
    else
      break
    end
  end

  numbers << [start, current.join.to_i, origin]
end

puts(numbers.group_by { |(_start, _number, origin)| origin }
  .keep_if { |_origin, numbers| numbers.size == 2 }
  .reduce(0) do |sum, (origin, numbers)|
    sum + (numbers[0][1] * numbers[1][1])
  end)

