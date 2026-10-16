package matrix_copy

import "core:c"

MAX_DIMENSION :: 32

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(byte * 8))
	}
}

@(export)
matrix_copy :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(2 + MAX_DIMENSION * MAX_DIMENSION) do return -1
	rows_value := values[0]
	columns_value := values[1]
	if rows_value < 0 || rows_value > MAX_DIMENSION || columns_value < 0 || columns_value > MAX_DIMENSION do return -1
	rows := int(rows_value)
	columns := int(columns_value)
	element_count := rows * columns
	if length != c.size_t(2 + element_count) do return -1
	for index := 0; index < element_count; index += 1 {
		if values[2 + index] < -2_147_483_648 || values[2 + index] > 2_147_483_647 do return -1
	}
	result_rows := 0
	result_columns := 0
	if rows > 0 && columns > 0 { result_rows = rows; result_columns = columns }
	result_count := result_rows * result_columns
	output_bytes := (2 + result_count) * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	store_i64_le(output, 0, i64(result_rows))
	store_i64_le(output, 8, i64(result_columns))
	for index := 0; index < result_count; index += 1 {
		store_i64_le(output, 16 + index * 8, values[2 + index])
	}
	return i64(output_bytes)
}
