module mirror_of_matrix

const max_dimension = 16
const max_parseable_input_length = 259

fn store_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'mirror_of_matrix']
pub fn mirror_of_matrix(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > usize(max_parseable_input_length) { return -1 }
		raw_rows := values[0]
		raw_columns := values[1]
		if raw_rows < 1 || raw_rows > max_dimension || raw_columns < 1 || raw_columns > max_dimension { return -1 }
		rows := int(raw_rows)
		columns := int(raw_columns)
		cell_count := rows * columns
		if length != usize(2 + cell_count) { return -1 }
		for index := 0; index < cell_count; index++ {
			cell := values[2 + index]
			if cell < -2147483648 || cell > 2147483647 { return -1 }
		}

		byte_count := 4 * cell_count
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for row := 0; row < rows; row++ {
			for column := 0; column < columns; column++ {
				source_index := 2 + row * columns + (columns - 1 - column)
				store_i32_le(output, 4 * (row * columns + column), i32(values[source_index]))
			}
		}
		return i64(byte_count)
	}
}
