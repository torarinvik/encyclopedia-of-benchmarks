module main

const max_dimension = 32

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'matrix_copy']
pub fn matrix_copy(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(2 + max_dimension * max_dimension) { return -1 }
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 0 || rows_value > max_dimension || columns_value < 0 || columns_value > max_dimension { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		element_count := rows * columns
		if int(length) != 2 + element_count { return -1 }
		for index in 0 .. element_count {
			if input[2 + index] < -2_147_483_648 || input[2 + index] > 2_147_483_647 { return -1 }
		}
		mut result_rows := 0
		mut result_columns := 0
		if rows > 0 && columns > 0 { result_rows = rows; result_columns = columns }
		result_count := result_rows * result_columns
		output_bytes := (2 + result_count) * 8
		if output == nil || int(output_capacity) < output_bytes { return -2 }
		store_i64_le(mut output, 0, i64(result_rows))
		store_i64_le(mut output, 8, i64(result_columns))
		for index in 0 .. result_count {
			store_i64_le(mut output, 16 + index * 8, input[2 + index])
		}
		return i64(output_bytes)
	}
}
