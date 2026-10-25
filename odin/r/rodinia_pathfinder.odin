package rodinia_pathfinder

import "core:c"

// Bounded row-wise minimum-cost path through a grid.
@(export)
rodinia_pathfinder :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 1027 do return -1
	if input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 32 ||
		input[2] < 1 || input[2] > 4 do return -1
	cols := int(input[0]); rows := int(input[1]); height := int(input[2])
	cells := cols * rows
	if length != c.size_t(3 + cells) do return -1
	for i in 0 ..< cells {
		if input[3 + i] < 0 || input[3 + i] > 9 do return -1
	}
	previous: [32]i64
	current: [32]i64
	for col in 0 ..< cols do previous[col] = input[3 + col]
	first := 1
	for first < rows {
		steps := min(height, rows - first)
		for step in 0 ..< steps {
			row := first + step
			for col in 0 ..< cols {
				best := previous[col]
				if col > 0 && previous[col - 1] < best do best = previous[col - 1]
				if col + 1 < cols && previous[col + 1] < best do best = previous[col + 1]
				current[col] = best + input[3 + row*cols + col]
			}
			for col in 0 ..< cols do previous[col] = current[col]
		}
		first += height
	}
	answer := previous[0]
	for col in 1 ..< cols {
		if previous[col] < answer do answer = previous[col]
	}
	return answer
}
