module median_of_matrix

const max_rows = 16
const max_cells = 128
const max_input_words = 145

fn put_i32_le(mut output &u8, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'median_of_matrix']
pub fn median_of_matrix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_words) { return -1 }
		if input[0] < 0 || input[0] > max_rows { return -1 }

		row_count := int(input[0])
		input_length := int(length)
		mut cursor := 1
		mut value_count := 0
		mut values := [max_cells]i32{}
		for _ in 0 .. row_count {
			if cursor >= input_length { return -1 }
			row_length := input[cursor]
			cursor++
			if row_length == -1 { continue }
			if row_length < 0 || row_length > max_cells { return -1 }
			cells := int(row_length)
			if cells > max_cells - value_count || cells > input_length - cursor { return -1 }
			for _ in 0 .. cells {
				value := input[cursor]
				cursor++
				if value < -2147483648 || value > 2147483647 { return -1 }
				values[value_count] = i32(value)
				value_count++
			}
		}
		if cursor != input_length || value_count == 0 { return -1 }

		for index := 1; index < value_count; index++ {
			value := values[index]
			mut position := index
			for position > 0 && values[position - 1] > value {
				values[position] = values[position - 1]
				position--
			}
			values[position] = value
		}

		if output == nil || capacity < 4 { return -2 }
		mut buffer := [4]u8{}
		put_i32_le(mut buffer[0], values[(value_count - 1) / 2])
		for byte in 0 .. 4 { output[byte] = buffer[byte] }
		return 4
	}
}
