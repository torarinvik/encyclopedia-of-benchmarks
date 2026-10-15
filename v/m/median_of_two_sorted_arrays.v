module median_of_two_sorted_arrays

const max_total_length = 1024

// Merge two ascending i32 arrays and return twice their exact median.
@[export: 'median_of_two_sorted_arrays']
pub fn median_of_two_sorted_arrays(input &i64, length usize) i64 {
	if length < 3 || length > max_total_length + 2 { return -1 }
	first_count_value := unsafe { input[0] }
	second_count_value := unsafe { input[1] }
	if first_count_value < 0 || first_count_value > max_total_length ||
		second_count_value < 0 || second_count_value > max_total_length { return -1 }
	first_count := usize(first_count_value)
	second_count := usize(second_count_value)
	total_count := first_count + second_count
	if total_count == 0 || total_count > max_total_length || length != total_count + 2 { return -1 }
	second_start := first_count + 2
	for index in 0 .. first_count {
		value := unsafe { input[index + 2] }
		if value < -2147483648 || value > 2147483647 ||
			(index > 0 && unsafe { input[index + 1] > value }) { return -1 }
	}
	for index in 0 .. second_count {
		value := unsafe { input[second_start + index] }
		if value < -2147483648 || value > 2147483647 ||
			(index > 0 && unsafe { input[second_start + index - 1] > value }) { return -1 }
	}

	mut merged := [max_total_length]i32{}
	mut first_index := usize(0)
	mut second_index := usize(0)
	mut written := usize(0)
	for first_index < first_count && second_index < second_count {
		if unsafe { input[first_index + 2] <= input[second_start + second_index] } {
			merged[written] = i32(unsafe { input[first_index + 2] })
			first_index++
		} else {
			merged[written] = i32(unsafe { input[second_start + second_index] })
			second_index++
		}
		written++
	}
	for first_index < first_count {
		merged[written] = i32(unsafe { input[first_index + 2] })
		first_index++
		written++
	}
	for second_index < second_count {
		merged[written] = i32(unsafe { input[second_start + second_index] })
		second_index++
		written++
	}
	if total_count % 2 != 0 { return i64(merged[total_count / 2]) * 2 }
	return i64(merged[total_count / 2 - 1]) + i64(merged[total_count / 2])
}
