module merge_two_sorted_lists

const max_total_length = 1024

// Linear merge over two packed ascending i32 sequences.
@[export: 'merge_two_sorted_lists']
pub fn merge_two_sorted_lists(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_total_length + 2 { return -1 }
	first_count_value := unsafe { input[0] }
	second_count_value := unsafe { input[1] }
	if first_count_value < 0 || first_count_value > max_total_length ||
		second_count_value < 0 || second_count_value > max_total_length { return -1 }
	first_count := usize(first_count_value)
	second_count := usize(second_count_value)
	if first_count + second_count > max_total_length || length != first_count + second_count + 2 { return -1 }
	for index in 0 .. first_count {
		value := unsafe { input[index + 2] }
		if value < -2147483648 || value > 2147483647 ||
			(index > 0 && unsafe { input[index + 1] } > value) { return -1 }
	}
	second_start := first_count + 2
	for index in 0 .. second_count {
		value := unsafe { input[second_start + index] }
		if value < -2147483648 || value > 2147483647 ||
			(index > 0 && unsafe { input[second_start + index - 1] } > value) { return -1 }
	}

	total_count := first_count + second_count
	output_bytes := total_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && unsafe { output == nil }) { return -2 }
	mut first_index := usize(0)
	mut second_index := usize(0)
	for written in 0 .. total_count {
		mut value := i64(0)
		if first_index == first_count {
			value = unsafe { input[second_start + second_index] }
			second_index++
		} else if second_index == second_count {
			value = unsafe { input[first_index + 2] }
			first_index++
		} else if unsafe { input[first_index + 2] <= input[second_start + second_index] } {
			value = unsafe { input[first_index + 2] }
			first_index++
		} else {
			value = unsafe { input[second_start + second_index] }
			second_index++
		}
		bits := u32(i32(value))
		for byte in 0 .. 4 {
			unsafe { output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
		}
	}
	return i64(total_count)
}
