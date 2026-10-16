package dilation_operation

import "core:c"

MAX_DIMENSION :: 16
MAX_INPUT_LENGTH :: 2 + MAX_DIMENSION * MAX_DIMENSION + 9

put_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(8 * byte)) & 255)
	}
}

@(export)
dilation_operation :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 12 || length > MAX_INPUT_LENGTH do return -1
	rows_value, columns_value := input[0], input[1]
	if rows_value < 1 || rows_value > MAX_DIMENSION || columns_value < 1 || columns_value > MAX_DIMENSION do return -1
	rows, columns := int(rows_value), int(columns_value)
	cells := rows * columns
	if length != c.size_t(2 + cells + 9) do return -1
	for i := 0; i < cells + 9; i += 1 {
		if input[2 + i] < 0 || input[2 + i] > 1 do return -1
	}
	if output == nil || output_capacity < c.size_t(cells * 4) do return -2
	for y := 0; y < rows; y += 1 {
		for x := 0; x < columns; x += 1 {
			sum := 0
			for ky := 0; ky < 3; ky += 1 {
				for kx := 0; kx < 3; kx += 1 {
					image_y, image_x := y + ky - 1, x + kx - 1
					if image_y >= 0 && image_y < rows && image_x >= 0 && image_x < columns {
						sum += int(input[2 + image_y * columns + image_x] * input[2 + cells + ky * 3 + kx])
					}
				}
			}
			put_i32_le(output, (y * columns + x) * 4, i32(if sum > 0 { 1 } else { 0 }))
		}
	}
	return i64(cells)
}
