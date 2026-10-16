module maximum_circular_subarray

@[export: 'maximum_circular_subarray']
pub fn maximum_circular_subarray(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length == 0 || length > 64 { return i64(-9223372036854775807) - 1 }
		for index in 0 .. int(length) {
			if values[index] < -1000000 || values[index] > 1000000 { return i64(-9223372036854775807) - 1 }
		}

		mut total := values[0]
		mut current_max := values[0]
		mut max_so_far := values[0]
		mut current_min := values[0]
		mut min_so_far := values[0]
		for index in 1 .. int(length) {
			value := values[index]
			current_max = if current_max + value > value { current_max + value } else { value }
			if current_max > max_so_far { max_so_far = current_max }
			current_min = if current_min + value < value { current_min + value } else { value }
			if current_min < min_so_far { min_so_far = current_min }
			total += value
		}
		if min_so_far == total { return max_so_far }
		return if max_so_far > total - min_so_far { max_so_far } else { total - min_so_far }
	}
}
