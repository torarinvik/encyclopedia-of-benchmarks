module median_of_two_sorted_arrays_partition

const max_array_length = 1000

// Find twice the median by binary-searching a partition of the shorter array.
@[export: 'median_of_two_sorted_arrays_partition']
pub fn median_of_two_sorted_arrays_partition(input &i64, length usize) i64 {
	if length < 3 || length > 2 * max_array_length + 2 { return -2000001 }
	first_count_value := unsafe { input[0] }
	second_count_value := unsafe { input[1] }
	if first_count_value < 0 || first_count_value > max_array_length ||
		second_count_value < 0 || second_count_value > max_array_length { return -2000001 }
	first_count := usize(first_count_value)
	second_count := usize(second_count_value)
	total_count := first_count + second_count
	if total_count == 0 || total_count > 2 * max_array_length || length != total_count + 2 {
		return -2000001
	}
	first_start := usize(2)
	second_start := first_start + first_count
	for index in 0 .. first_count {
		value := unsafe { input[first_start + index] }
		if value < -1000000 || value > 1000000 ||
			(index > 0 && unsafe { input[first_start + index - 1] > value }) { return -2000001 }
	}
	for index in 0 .. second_count {
		value := unsafe { input[second_start + index] }
		if value < -1000000 || value > 1000000 ||
			(index > 0 && unsafe { input[second_start + index - 1] > value }) { return -2000001 }
	}

	mut short_start := first_start
	mut long_start := second_start
	mut short_count := first_count
	mut long_count := second_count
	if short_count > long_count {
		temporary_start := short_start
		short_start = long_start
		long_start = temporary_start
		temporary_count := short_count
		short_count = long_count
		long_count = temporary_count
	}
	mut low := usize(0)
	mut high := short_count
	left_count := (total_count + 1) / 2
	for low <= high {
		first_cut := low + (high - low) / 2
		second_cut := left_count - first_cut
		first_left := if first_cut == 0 { i64(-2000001) } else { unsafe { input[short_start + first_cut - 1] } }
		first_right := if first_cut == short_count { i64(2000001) } else { unsafe { input[short_start + first_cut] } }
		second_left := if second_cut == 0 { i64(-2000001) } else { unsafe { input[long_start + second_cut - 1] } }
		second_right := if second_cut == long_count { i64(2000001) } else { unsafe { input[long_start + second_cut] } }
		if first_left <= second_right && second_left <= first_right {
			left_max := if first_left > second_left { first_left } else { second_left }
			if total_count % 2 != 0 { return left_max * 2 }
			right_min := if first_right < second_right { first_right } else { second_right }
			return left_max + right_min
		}
		if first_left > second_right {
			if first_cut == 0 { return -2000001 }
			high = first_cut - 1
		} else {
			low = first_cut + 1
		}
	}
	return -2000001
}
