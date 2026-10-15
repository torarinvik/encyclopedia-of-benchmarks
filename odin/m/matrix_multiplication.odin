package matrix_multiplication

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
matrix_multiplication :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -2
	dimension := input[0]
	if dimension < 2 || dimension > 8 do return -2
	n := int(dimension)
	cells := n * n
	if length != c.size_t(1 + 2 * cells) do return -2
	for index := 0; index < 2 * cells; index += 1 {
		if input[1 + index] < -1000 || input[1 + index] > 1000 do return -2
	}
	if output == nil || output_capacity < c.size_t(cells * 8) do return -3

	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			sum := i64(0)
			for index := 0; index < n; index += 1 {
				sum += input[1 + row*n + index] * input[1 + cells + index*n + column]
			}
			store_i64_le(output, (row*n+column)*8, sum)
		}
	}
	return i64(cells)
}
