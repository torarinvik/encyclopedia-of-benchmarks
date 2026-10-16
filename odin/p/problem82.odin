package problem82

import "core:c"

@(export)
problem82 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	row_value := input[0]
	column_value := input[1]
	if row_value < 1 || row_value > 80 || column_value < 1 || column_value > 80 do return -1
	rows := int(row_value)
	columns := int(column_value)
	if int(length) != 2 + rows * columns do return -1
	for index := 2; index < int(length); index += 1 {
		if input[index] < 0 || input[index] > 9999 do return -1
	}

	costs: [80]i64
	for row := 0; row < rows; row += 1 do costs[row] = input[2 + row * columns]
	for column := 1; column < columns; column += 1 {
		offset := 2 + column
		for row := 0; row < rows; row += 1 do costs[row] += input[offset + row * columns]
		for row := 1; row < rows; row += 1 {
			from_above := costs[row - 1] + input[offset + row * columns]
			if from_above < costs[row] do costs[row] = from_above
		}
		row := rows - 1
		for row > 0 {
			from_below := costs[row] + input[offset + (row - 1) * columns]
			if from_below < costs[row - 1] do costs[row - 1] = from_below
			row -= 1
		}
	}
	best := costs[0]
	for row := 1; row < rows; row += 1 do if costs[row] < best do best = costs[row]
	return best
}
