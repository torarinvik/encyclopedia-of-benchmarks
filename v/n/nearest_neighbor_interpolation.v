module nearest_neighbor_interpolation

const max_input_length = 258

@[export: 'nearest_neighbor_interpolation']
pub fn nearest_neighbor_interpolation(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > 16 || columns_value < 1 || columns_value > 16 { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		input_cells := rows * columns
		if length != usize(2 + input_cells) { return -1 }
		for index in 0 .. input_cells {
			if input[2 + index] < 0 || input[2 + index] > 255 { return -1 }
		}

		output_rows := 3 * rows / 2
		output_columns := 3 * columns / 2
		output_bytes := output_rows * output_columns
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for y in 0 .. output_rows {
			source_y := (4 * (y + 1) + 3) / 6 - 1
			for x in 0 .. output_columns {
				source_x := (4 * (x + 1) + 3) / 6 - 1
				output[y * output_columns + x] = u8(input[2 + source_y * columns + source_x])
			}
		}
		return i64(output_bytes)
	}
}
