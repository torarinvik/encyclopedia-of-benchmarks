module union_of_two_arrays

const max_array_length = 64
const max_input_length = 2 * (max_array_length + 1)
const bytes_per_value = 4

fn store_i32_le(mut output &u8, position int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. bytes_per_value {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'union_of_two_arrays']
pub fn union_of_two_arrays(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	first_length_value := unsafe { input[0] }
	if first_length_value < 0 || first_length_value > max_array_length { return -1 }
	first_length := int(first_length_value)
	second_length_position := 1 + first_length
	if second_length_position >= int(length) { return -1 }
	second_length_value := unsafe { input[second_length_position] }
	if second_length_value < 0 || second_length_value > max_array_length { return -1 }
	second_length := int(second_length_value)
	second_start := second_length_position + 1
	if second_start + second_length != int(length) { return -1 }

	for index := 0; index < first_length; index++ {
		value := unsafe { input[1 + index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		if index > 0 && unsafe { input[index] > value } { return -1 }
	}
	for index := 0; index < second_length; index++ {
		value := unsafe { input[second_start + index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		if index > 0 && unsafe { input[second_start + index - 1] > value } { return -1 }
	}

	maximum_result := first_length + second_length
	if output_capacity < usize(maximum_result * bytes_per_value) || (maximum_result > 0 && unsafe { output == nil }) { return -2 }
	mut first_index := 0
	mut second_index := 0
	mut result_count := 0
	mut previous_value := i64(0)
	for first_index < first_length || second_index < second_length {
		mut value := i64(0)
		if first_index == first_length {
			value = unsafe { input[second_start + second_index] }
			second_index++
		} else if second_index == second_length {
			value = unsafe { input[1 + first_index] }
			first_index++
		} else {
			first := unsafe { input[1 + first_index] }
			second := unsafe { input[second_start + second_index] }
			if first < second {
				value = first
				first_index++
			} else if first > second {
				value = second
				second_index++
			} else {
				value = first
				first_index++
				second_index++
			}
		}
		if result_count == 0 || value != previous_value {
			store_i32_le(mut output, result_count * bytes_per_value, value)
			previous_value = value
			result_count++
		}
	}
	return i64(result_count)
}
