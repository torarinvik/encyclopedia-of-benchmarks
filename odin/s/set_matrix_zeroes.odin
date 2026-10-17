package set_matrix_zeroes

import "core:c"

MAX_INPUT_LENGTH :: 67
MAX_CELLS :: 64
MIN_CELL :: i64(-1_000_000)
MAX_CELL :: i64(1_000_000)

write_i64_le :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[position + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
set_matrix_zeroes :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	rows_value, columns_value := input[0], input[1]
	if rows_value < 1 || rows_value > 8 || columns_value < 1 || columns_value > 8 do return -1
	rows, columns := int(rows_value), int(columns_value)
	cells := rows * columns
	if length != c.size_t(2 + cells) do return -1

	matrix: [MAX_CELLS]i64 = {}
	for index := 0; index < cells; index += 1 {
		value := input[2 + index]
		if value < MIN_CELL || value > MAX_CELL do return -1
		matrix[index] = value
	}

	bytes := cells * 8
	if output == nil || capacity < c.size_t(bytes) do return -2

	first_column_zero := false
	for row := 0; row < rows; row += 1 {
		if matrix[row * columns] == 0 do first_column_zero = true
		for column := 1; column < columns; column += 1 {
			if matrix[row * columns + column] == 0 {
				matrix[row * columns] = 0
				matrix[column] = 0
			}
		}
	}
	for row := 1; row < rows; row += 1 {
		for column := 1; column < columns; column += 1 {
			if matrix[row * columns] == 0 || matrix[column] == 0 do matrix[row * columns + column] = 0
		}
	}
	if matrix[0] == 0 {
		for column := 0; column < columns; column += 1 do matrix[column] = 0
	}
	if first_column_zero {
		for row := 0; row < rows; row += 1 do matrix[row * columns] = 0
	}

	for index := 0; index < cells; index += 1 do write_i64_le(output, index * 8, matrix[index])
	return i64(bytes)
}
