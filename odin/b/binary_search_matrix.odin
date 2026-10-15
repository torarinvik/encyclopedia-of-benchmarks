package binary_search_matrix

import "core:c"

search_row :: proc(values: [^]i64, base: c.size_t, lower, upper, target: i64) -> i64 {
	middle := (lower + upper) / 2
	value := values[base + c.size_t(middle)]
	if value == target do return middle
	if lower >= upper do return -1
	if value < target do return search_row(values, base, middle + 1, upper, target)
	return search_row(values, base, lower, middle - 1, target)
}

@(export)
binary_search_matrix :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 do return -1
	rows_value, columns_value, target := values[0], values[1], values[2]
	if rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32 do return -1
	rows, columns := c.size_t(rows_value), c.size_t(columns_value)
	if length != 3 + rows * columns do return -1
	if values[3] == target do return 0
	row: c.size_t = 0
	for row < rows && values[3 + row * columns] < target {
		column := search_row(values, 3 + row * columns, 0, i64(columns) - 1, target)
		if column != -1 do return i64(row * columns) + column
		row += 1
	}
	return -1
}
