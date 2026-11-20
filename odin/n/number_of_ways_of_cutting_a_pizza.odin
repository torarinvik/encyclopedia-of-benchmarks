package number_of_ways_of_cutting_a_pizza

import "core:c"

MAX_INPUT :: 39
MODULUS :: i64(1000000007)

@(export)
number_of_ways_of_cutting_a_pizza :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	rows_value, columns_value, cuts_value := input[0], input[1], input[2]
	if rows_value < 1 || rows_value > 6 || columns_value < 1 || columns_value > 6 do return -1
	if cuts_value < 0 || cuts_value > 5 do return -1
	rows, columns, cuts := int(rows_value), int(columns_value), int(cuts_value)
	if length != c.size_t(3 + rows*columns) do return -1

	cells: [36]i64
	for index := 0; index < rows*columns; index += 1 {
		cell := input[3+index]
		if cell != 0 && cell != 1 do return -1
		cells[index] = cell
	}
	suffix: [49]i64
	for row_offset := 0; row_offset < rows; row_offset += 1 {
		row := rows - 1 - row_offset
		for column_offset := 0; column_offset < columns; column_offset += 1 {
			column := columns - 1 - column_offset
			at := row*7 + column
			suffix[at] = cells[row*columns+column] + suffix[(row+1)*7+column] +
				suffix[row*7+column+1] - suffix[(row+1)*7+column+1]
		}
	}

	previous, current: [49]i64
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			if suffix[row*7+column] > 0 do previous[row*7+column] = 1
		}
	}
	for remaining := 1; remaining <= cuts; remaining += 1 {
		for index := 0; index < 49; index += 1 do current[index] = 0
		for row_offset := 0; row_offset < rows; row_offset += 1 {
			row := rows - 1 - row_offset
			for column_offset := 0; column_offset < columns; column_offset += 1 {
				column := columns - 1 - column_offset
				origin := row*7 + column
				ways: i64 = 0
				for cut_row := row+1; cut_row < rows; cut_row += 1 {
					if suffix[origin]-suffix[cut_row*7+column] > 0 do ways += previous[cut_row*7+column]
				}
				for cut_column := column+1; cut_column < columns; cut_column += 1 {
					if suffix[origin]-suffix[row*7+cut_column] > 0 do ways += previous[row*7+cut_column]
				}
				current[origin] = ways % MODULUS
			}
		}
		for index := 0; index < 49; index += 1 do previous[index] = current[index]
	}
	return previous[0]
}
