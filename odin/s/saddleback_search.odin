package saddleback_search

import "core:c"

@(export)
saddleback_search :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 do return -1
	rows_value, columns_value, target := values[0], values[1], values[2]
	if rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32 do return -1
	if target < -2147483648 || target > 2147483647 do return -1
	rows, columns := c.size_t(rows_value), c.size_t(columns_value)
	cells := rows * columns
	if length != 3 + cells do return -1
	for index: c.size_t = 0; index < cells; index += 1 {
		value := values[3 + index]
		if value < -2147483648 || value > 2147483647 do return -1
	}

	row: c.size_t = 0
	column := columns - 1
	for row < rows {
		value := values[3 + row * columns + column]
		if value == target do return i64(row * columns + column + 1)
		if value < target {
			row += 1
		} else if column == 0 {
			break
		} else {
			column -= 1
		}
	}
	return 0
}
