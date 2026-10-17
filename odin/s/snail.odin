package snail

import "core:c"

MAX_CELLS :: 256
MAX_INPUT_LENGTH :: 259

write_i32_le :: proc "contextless" (output: [^]u8, index: int, value: i32) {
	bits := transmute(u32)value
	offset := index * 4
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

snail :: proc "c" (values: [^]i32, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	rows_value, columns_value := values[0], values[1]
	if rows_value < 0 || rows_value > 16 || columns_value < 0 || columns_value > 16 do return -1
	if rows_value == 0 && columns_value != 0 do return -1
	if columns_value == 1 && rows_value != 1 do return -1

	rows, columns := int(rows_value), int(columns_value)
	cell_count := rows * columns
	if int(length) != 2 + cell_count do return -1

	required_bytes := 4 * cell_count
	if output == nil || output_capacity < c.size_t(required_bytes) do return -2
	if cell_count == 0 do return 0

	matrix: [MAX_CELLS]i32
	for index := 0; index < cell_count; index += 1 {
		matrix[index] = values[2+index]
	}

	top, bottom, left, right := 0, rows-1, 0, columns-1
	written := 0
	for top <= bottom && left <= right {
		for column := left; column <= right; column += 1 {
			write_i32_le(output, written, matrix[top*columns+column])
			written += 1
		}
		top += 1

		for row := top; row <= bottom; row += 1 {
			write_i32_le(output, written, matrix[row*columns+right])
			written += 1
		}
		right -= 1

		if top <= bottom && left <= right {
			for column := right; column >= left; column -= 1 {
				write_i32_le(output, written, matrix[bottom*columns+column])
				written += 1
			}
			bottom -= 1
		}

		if top <= bottom && left <= right {
			for row := bottom; row >= top; row -= 1 {
				write_i32_le(output, written, matrix[row*columns+left])
				written += 1
			}
			left += 1
		}
	}
	return i64(required_bytes)
}
