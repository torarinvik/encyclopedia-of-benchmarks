module maximum_product_subarray

@[export: 'maximum_product_subarray']
pub fn maximum_product_subarray(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length == 0 || length > 9 { return i64(-9223372036854775807) - 1 }
		for index in 0 .. int(length) {
			if values[index] < -10 || values[index] > 10 { return i64(-9223372036854775807) - 1 }
		}

		mut current_max := values[0]
		mut current_min := values[0]
		mut best := values[0]
		for index in 1 .. int(length) {
			value := values[index]
			prior_max := current_max
			prior_min := current_min
			from_max := prior_max * value
			from_min := prior_min * value
			current_max = max(value, max(from_max, from_min))
			current_min = min(value, min(from_max, from_min))
			best = max(best, current_max)
		}
		return best
	}
}
