package nearest_neighbor_interpolation

import "core:c"

@(export)
nearest_neighbor_interpolation :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 258 do return -1
	rows_value, columns_value := input[0], input[1]
	if rows_value < 1 || rows_value > 16 || columns_value < 1 || columns_value > 16 do return -1
	rows, columns := int(rows_value), int(columns_value)
	input_cells := rows * columns
	if length != c.size_t(2 + input_cells) do return -1
	for index := 0; index < input_cells; index += 1 {
		if input[2 + index] < 0 || input[2 + index] > 255 do return -1
	}

	output_rows, output_columns := 3 * rows / 2, 3 * columns / 2
	output_bytes := output_rows * output_columns
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for y := 0; y < output_rows; y += 1 {
		source_y := (4 * (y + 1) + 3) / 6 - 1
		for x := 0; x < output_columns; x += 1 {
			source_x := (4 * (x + 1) + 3) / 6 - 1
			output[y * output_columns + x] = u8(input[2 + source_y * columns + source_x])
		}
	}
	return i64(output_bytes)
}
