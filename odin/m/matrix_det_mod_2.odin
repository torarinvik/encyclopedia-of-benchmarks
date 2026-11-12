package matrix_det_mod_2

import "core:c"

MAX_N :: 64
MAX_INPUT_VALUES :: 1 + MAX_N * MAX_N

store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
matrix_det_mod_2 :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	if n_value < 1 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if length != c.size_t(1 + n * n) do return -1

	rows: [MAX_N]u64
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			bit := input[1 + row * n + column]
			if bit != 0 && bit != 1 do return -1
			rows[row] |= u64(bit) << u64(column)
		}
	}

	pivot_row := 0
	for column := 0; column < n; column += 1 {
		pivot := pivot_row
		for pivot < n && ((rows[pivot] >> u64(column)) & 1) == 0 do pivot += 1
		if pivot == n do continue
		temporary := rows[pivot_row]
		rows[pivot_row] = rows[pivot]
		rows[pivot] = temporary
		for row := pivot_row + 1; row < n; row += 1 {
			if ((rows[row] >> u64(column)) & 1) != 0 do rows[row] = rows[row] ^ rows[pivot_row]
		}
		pivot_row += 1
	}
	if output == nil || capacity < 8 do return -2
	result := i64(0)
	if pivot_row == n do result = 1
	store_i64_le(output, result)
	return 8
}
