package tsvc_s2111_wavefront_add_recurrence

import "core:c"

MAX_SIDE :: 8
MAX_PASSES :: 4
MAX_CELLS :: MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH :: 2 + MAX_CELLS

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s2111_wavefront_add_recurrence :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	side_raw := input[0]
	passes_raw := input[1]
	if side_raw < 2 || side_raw > MAX_SIDE || passes_raw < 1 || passes_raw > MAX_PASSES do return -1
	side := int(side_raw)
	cells := side * side
	if int(length) != 2 + cells do return -1

	var matrix: [MAX_CELLS]i64
	for cell := 0; cell < cells; cell += 1 {
		value := input[2 + cell]
		if value < -8 || value > 8 do return -1
		matrix[cell] = value
	}
	if output == nil || output_capacity < c.size_t(8 * cells) do return -2

	for pass := 0; pass < int(passes_raw); pass += 1 {
		for row := 1; row < side; row += 1 {
			for col := 1; col < side; col += 1 {
				matrix[row * side + col] = matrix[row * side + col - 1] + matrix[(row - 1) * side + col]
			}
		}
	}
	for cell := 0; cell < cells; cell += 1 { store_i64_le(output, 8 * cell, matrix[cell]) }
	return i64(cells)
}
