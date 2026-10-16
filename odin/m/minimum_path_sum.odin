package minimum_path_sum

import "core:c"

@(export)
minimum_path_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 66 do return -9223372036854775807 - 1
	row_value := values[0]
	column_value := values[1]
	if row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8 do return -9223372036854775807 - 1
	rows := int(row_value)
	columns := int(column_value)
	if int(length) != 2 + rows * columns do return -9223372036854775807 - 1
	costs: [8]i64 = {}
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			cell := values[2 + row * columns + column]
			if cell < 0 || cell > 1000 do return -9223372036854775807 - 1
			if row == 0 && column == 0 do costs[column] = cell
			else if row == 0 do costs[column] = costs[column - 1] + cell
			else if column == 0 do costs[column] += cell
			else if costs[column - 1] < costs[column] do costs[column] = costs[column - 1] + cell
			else do costs[column] += cell
		}
	}
	return costs[columns - 1]
}
