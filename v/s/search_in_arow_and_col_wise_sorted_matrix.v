const max_dimension = usize(63)
const max_input_values = usize(3971)

fn write_i32_le(mut output &u8, offset int, value i64) {
	mut bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'search_in_arow_and_col_wise_sorted_matrix']
pub fn search_in_arow_and_col_wise_sorted_matrix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		n_value := input[0]
		target := input[1]
		if n_value < 1 || n_value > i64(max_dimension) || target < -2_147_483_648 || target > 2_147_483_647 { return -1 }
		n := int(n_value)
		if length != usize(2 + n * n) { return -1 }

		mut target_count := 0
		for row in 0 .. n {
			for column in 0 .. n {
				index := row * n + column
				value := input[2 + index]
				if value < -2_147_483_648 || value > 2_147_483_647 { return -1 }
				if column > 0 && value < input[2 + index - 1] { return -1 }
				if row > 0 && value < input[2 + index - n] { return -1 }
				if value == target {
					target_count++
					if target_count > 1 { return -1 }
				}
			}
		}

		mut row := 0
		mut column := n - 1
		mut result_row := i64(-1)
		mut result_column := i64(-1)
		mut found := i64(0)
		for row < n && column >= 0 {
			value := input[2 + row * n + column]
			if value == target {
				result_row = i64(row)
				result_column = i64(column)
				found = 1
				break
			}
			if target > value { row++ } else { column-- }
		}

		if output == nil || capacity < 8 { return -2 }
		mut buffer := [8]u8{}
		write_i32_le(mut buffer, 0, result_row)
		write_i32_le(mut buffer, 4, result_column)
		for index in 0 .. 8 { output[index] = buffer[index] }
		return found
	}
}
