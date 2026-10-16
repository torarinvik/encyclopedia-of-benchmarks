package problem18

import "core:c"

@(export)
problem18 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 121 do return -1
	rows := input[0]
	if rows < 1 || rows > 15 || int(length) != int(rows * (rows + 1) / 2) + 1 do return -1
	best: [120]i64 = {}
	value_count := int(length) - 1
	for index := 0; index < value_count; index += 1 {
		value := input[index + 1]
		if value < 0 || value > 1_000_000 do return -1
		best[index] = value
	}
	row := rows - 1
	for row > 0 {
		parent_start := int((row - 1) * row / 2)
		child_start := int(row * (row + 1) / 2)
		for column := 0; column < int(row); column += 1 {
			parent := parent_start + column
			child := child_start + column
			left := best[child]
			right := best[child + 1]
			best[parent] += if left > right then left else right
		}
		row -= 1
	}
	return best[0]
}
