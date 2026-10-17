module snail

const max_cells = 256
const max_input_length = 259

fn write_i32_le(mut output &u8, index int, value i32) {
	unsafe {
		bits := u32(value)
		offset := index * 4
		for byte in 0 .. 4 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'snail']
pub fn snail(values &i32, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > max_input_length { return -1 }
		rows_value, columns_value := values[0], values[1]
		if rows_value < 0 || rows_value > 16 || columns_value < 0 || columns_value > 16 { return -1 }
		if rows_value == 0 && columns_value != 0 { return -1 }
		if columns_value == 1 && rows_value != 1 { return -1 }

		rows, columns := int(rows_value), int(columns_value)
		cell_count := rows * columns
		if length != usize(2 + cell_count) { return -1 }

		required_bytes := 4 * cell_count
		if output == nil || output_capacity < usize(required_bytes) { return -2 }
		if cell_count == 0 { return 0 }

		mut matrix := [max_cells]i32{}
		for index in 0 .. cell_count {
			matrix[index] = values[2 + index]
		}

		mut top, mut bottom := 0, rows - 1
		mut left, mut right := 0, columns - 1
		mut written := 0
		for top <= bottom && left <= right {
			for column in left .. right + 1 {
				write_i32_le(mut output, written, matrix[top * columns + column])
				written++
			}
			top++

			for row in top .. bottom + 1 {
				write_i32_le(mut output, written, matrix[row * columns + right])
				written++
			}
			right--

			if top <= bottom && left <= right {
				mut column := right
				for {
					write_i32_le(mut output, written, matrix[bottom * columns + column])
					written++
					if column == left { break }
					column--
				}
				bottom--
			}

			if top <= bottom && left <= right {
				mut row := bottom
				for {
					write_i32_le(mut output, written, matrix[row * columns + left])
					written++
					if row == top { break }
					row--
				}
				left++
			}
		}
		return i64(required_bytes)
	}
}
