package search_in_arow_and_col_wise_sorted_matrix

import "core:c"

MAX_DIMENSION :: 63
MAX_INPUT_VALUES :: 3971
INT32_MINIMUM :: i64(-2_147_483_648)
INT32_MAXIMUM :: i64(2_147_483_647)

write_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export, link_name="search_in_arow_and_col_wise_sorted_matrix")
search_in_arow_and_col_wise_sorted_matrix :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	target := input[1]
	if n_value < 1 || n_value > MAX_DIMENSION || target < INT32_MINIMUM || target > INT32_MAXIMUM do return -1
	n := int(n_value)
	if length != c.size_t(2 + n * n) do return -1

	target_count := 0
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			index := row * n + column
			value := input[2 + index]
			if value < INT32_MINIMUM || value > INT32_MAXIMUM do return -1
			if column > 0 && value < input[2 + index - 1] do return -1
			if row > 0 && value < input[2 + index - n] do return -1
			if value == target {
				target_count += 1
				if target_count > 1 do return -1
			}
		}
	}

	row := 0
	column := n - 1
	result_row := i64(-1)
	result_column := i64(-1)
	found := i64(0)
	for row < n && column >= 0 {
		value := input[2 + row * n + column]
		if value == target {
			result_row = i64(row)
			result_column = i64(column)
			found = 1
			break
		}
		if target > value { row += 1 } else { column -= 1 }
	}

	if output == nil || capacity < 8 do return -2
	buffer: [8]u8
	write_i32_le(buffer[:], 0, result_row)
	write_i32_le(buffer[:], 4, result_column)
	for index := 0; index < 8; index += 1 { output[index] = buffer[index] }
	return found
}
