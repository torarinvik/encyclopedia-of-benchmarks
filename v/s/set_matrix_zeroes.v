module set_matrix_zeroes

const max_input_length = usize(67)
const max_cells = 64
const min_cell = i64(-1_000_000)
const max_cell = i64(1_000_000)

fn write_i64_le(mut output &u8, position int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'set_matrix_zeroes']
pub fn set_matrix_zeroes(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > 8 || columns_value < 1 || columns_value > 8 { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		cells := rows * columns
		if length != usize(2 + cells) { return -1 }

		mut matrix := [max_cells]i64{}
		for index in 0 .. cells {
			value := input[2 + index]
			if value < min_cell || value > max_cell { return -1 }
			matrix[index] = value
		}

		bytes := cells * 8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }

		mut first_column_zero := false
		for row in 0 .. rows {
			if matrix[row * columns] == 0 { first_column_zero = true }
			for column in 1 .. columns {
				if matrix[row * columns + column] == 0 {
					matrix[row * columns] = 0
					matrix[column] = 0
				}
			}
		}
		for row in 1 .. rows {
			for column in 1 .. columns {
				if matrix[row * columns] == 0 || matrix[column] == 0 {
					matrix[row * columns + column] = 0
				}
			}
		}
		if matrix[0] == 0 {
			for column in 0 .. columns { matrix[column] = 0 }
		}
		if first_column_zero {
			for row in 0 .. rows { matrix[row * columns] = 0 }
		}

		for index in 0 .. cells { write_i64_le(mut output, index * 8, matrix[index]) }
		return i64(bytes)
	}
}
