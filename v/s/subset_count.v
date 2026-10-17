module subset_count

const max_input_length = usize(33)

@[export: 'subset_count']
pub fn subset_count(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		count_value := values[0]
		target := values[1]
		if count_value < 1 || count_value > 30 || target < 0 || target > 64 { return -1 }
		count := int(count_value)
		if length != usize(count + 2) { return -1 }
		for index in 0 .. count {
			value := values[index + 2]
			if value < 0 || value > 64 { return -1 }
		}

		mut previous := [65]i64{}
		previous[0] = 1
		if values[2] <= target { previous[int(values[2])] = 1 }

		for index in 1 .. count {
			mut current := [65]i64{}
			current[0] = 1
			for amount in 1 .. int(target) + 1 {
				value := values[index + 2]
				not_taken := previous[amount]
				mut taken := i64(0)
				if value <= i64(amount) { taken = previous[amount - int(value)] }
				current[amount] = not_taken + taken
			}
			previous = current
		}
		return previous[int(target)]
	}
}
