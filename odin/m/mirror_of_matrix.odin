package mirror_of_matrix

import "core:c"

MAX_DIMENSION :: 16
MAX_PARSEABLE_INPUT_LENGTH :: 259

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> u32(byte * 8))
	}
}

@(export)
mirror_of_matrix :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	raw_rows := values[0]
	raw_columns := values[1]
	if raw_rows < 1 || raw_rows > MAX_DIMENSION || raw_columns < 1 || raw_columns > MAX_DIMENSION do return -1
	rows := int(raw_rows)
	columns := int(raw_columns)
	cell_count := rows * columns
	if length != c.size_t(2 + cell_count) do return -1
	for index := 0; index < cell_count; index += 1 {
		cell := values[2 + index]
		if cell < -2147483648 || cell > 2147483647 do return -1
	}

	byte_count := 4 * cell_count
	if output == nil || output_capacity < c.size_t(byte_count) do return -2
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			source_index := 2 + row * columns + (columns - 1 - column)
			store_i32_le(output, 4 * (row * columns + column), i32(values[source_index]))
		}
	}
	return i64(byte_count)
}
