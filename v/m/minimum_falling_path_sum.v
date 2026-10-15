module minimum_falling_path_sum

@[export: 'minimum_falling_path_sum']
pub fn minimum_falling_path_sum(input &i64, length usize) i64 {
	if length < 1 { return -10001 }
	unsafe {
		if input[0] < 1 || input[0] > 100 { return -10001 }
		n := int(input[0])
		if int(length) != 1 + n * n { return -10001 }
		for index in 0 .. n * n {
			if input[1 + index] < -100 || input[1 + index] > 100 { return -10001 }
		}
		mut costs := [100]i64{}
		mut next_costs := [100]i64{}
		for column in 0 .. n { costs[column] = input[1 + column] }
		for row in 1 .. n {
			for column in 0 .. n {
				mut best := costs[column]
				if column > 0 && costs[column - 1] < best { best = costs[column - 1] }
				if column + 1 < n && costs[column + 1] < best { best = costs[column + 1] }
				next_costs[column] = best + input[1 + row * n + column]
			}
			for column in 0 .. n { costs[column] = next_costs[column] }
		}
		mut minimum := costs[0]
		for column in 1 .. n {
			if costs[column] < minimum { minimum = costs[column] }
		}
		return minimum
	}
}
