package largest_zero_submatrix

import "core:c"

MAX_ROWS :: 16
MAX_COLUMNS :: 16

@(export)
largest_zero_submatrix :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 259 do return -1
	rows_value, columns_value := input[0], input[1]
	if rows_value < 1 || rows_value > MAX_ROWS || columns_value < 1 || columns_value > MAX_COLUMNS do return -1
	rows, columns := int(rows_value), int(columns_value)
	if int(length) != 2 + rows * columns do return -1
	for index := 2; index < int(length); index += 1 {
		if input[index] != 0 && input[index] != 1 do return -1
	}

	last_one: [MAX_COLUMNS]i64
	left, right, stack: [MAX_COLUMNS]int
	for column := 0; column < columns; column += 1 do last_one[column] = -1
	best := i64(0)
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			if input[2 + row * columns + column] == 1 do last_one[column] = i64(row)
		}
		top := 0
		for column := 0; column < columns; column += 1 {
			for top > 0 && last_one[stack[top - 1]] <= last_one[column] do top -= 1
			left[column] = -1
			if top > 0 do left[column] = stack[top - 1]
			stack[top] = column
			top += 1
		}
		top = 0
		for cursor := columns - 1; cursor >= 0; cursor -= 1 {
			for top > 0 && last_one[stack[top - 1]] <= last_one[cursor] do top -= 1
			right[cursor] = columns
			if top > 0 do right[cursor] = stack[top - 1]
			stack[top] = cursor
			top += 1
		}
		for column := 0; column < columns; column += 1 {
			height := i64(row) - last_one[column]
			width := i64(right[column] - left[column] - 1)
			area := height * width
			if area > best do best = area
		}
	}
	return best
}
