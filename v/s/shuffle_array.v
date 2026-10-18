module shuffle_array

const max_n = 32
const max_parseable_input_length = 67
const max_output_bytes = 520
const i32_min = i64(-2147483648)
const i32_max = i64(2147483647)

fn store_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'shuffle_array']
pub fn shuffle_array(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_parseable_input_length { return -1 }
		variant := input[0]
		n_value := input[1]
		if (variant != 0 && variant != 1) || n_value < 0 || n_value > max_n { return -1 }
		n := int(n_value)
		value_count := n
		if variant == 1 { value_count = 2 * n }
		draw_count := 0
		if variant == 0 && n > 0 { draw_count = n - 1 }
		if input_length != usize(2 + value_count + draw_count) { return -1 }

		mut result_values := [2 * max_n]i64{}
		result_count := value_count
		for index in 0 .. value_count {
			value := input[2 + index]
			if value < i32_min || value > i32_max { return -1 }
			result_values[index] = value
		}

		if variant == 0 {
			for draw_index in 0 .. draw_count {
				current_index := n - 1 - draw_index
				chosen_value := input[2 + n + draw_index]
				if chosen_value < 0 || chosen_value > i64(current_index) { return -1 }
				chosen_index := int(chosen_value)
				temporary := result_values[current_index]
				result_values[current_index] = result_values[chosen_index]
				result_values[chosen_index] = temporary
			}
		} else {
			for index in 0 .. n {
				result_values[2 * index] = input[2 + index]
				result_values[2 * index + 1] = input[2 + n + index]
			}
		}

		output_bytes := 8 * (result_count + 1)
		if output_bytes > max_output_bytes || output == nil || output_capacity < usize(output_bytes) { return -2 }
		store_i64_le(output, 0, i64(result_count))
		for index in 0 .. result_count { store_i64_le(output, 8 * (index + 1), result_values[index]) }
		return i64(output_bytes)
	}
}
