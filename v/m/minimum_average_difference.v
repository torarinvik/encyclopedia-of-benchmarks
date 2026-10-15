module minimum_average_difference

const max_length = 100000

// Return the earliest split with the smallest difference of integer averages.
@[export: 'minimum_average_difference']
pub fn minimum_average_difference(values &i64, length usize) i64 {
	if length == 0 || length > max_length { return -1 }
	mut total_sum := i64(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > i64(100000) { return -1 }
		total_sum += value
	}
	mut prefix_sum := i64(0)
	mut best_difference := i64(9223372036854775807)
	mut best_index := usize(0)
	for index in 0 .. length {
		prefix_sum += unsafe { values[index] }
		left_average := prefix_sum / i64(index + 1)
		suffix_length := length - index - 1
		right_average := if suffix_length == 0 { i64(0) } else {
			(total_sum - prefix_sum) / i64(suffix_length)
		}
		difference := if left_average >= right_average {
			left_average - right_average
		} else {
			right_average - left_average
		}
		if difference < best_difference {
			best_difference = difference
			best_index = index
		}
	}
	return i64(best_index)
}
