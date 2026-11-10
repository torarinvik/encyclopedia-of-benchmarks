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
		mut costs := [102]u16{}
		mut next_costs := [100]u16{}
		costs[0] = 32768
		costs[n + 1] = 32768
		for column in 0 .. n {
			costs[column + 1] = u16(input[1 + column] + 100)
		}
		for row in 1 .. n {
			for column in 0 .. n {
				left := costs[column]
				center := costs[column + 1]
				right := costs[column + 2]
				left_or_center := if left < center { left } else { center }
				best := if right < left_or_center { right } else { left_or_center }
				next_costs[column] = best + u16(input[1 + row * n + column] + 100)
			}
			for column in 0 .. n {
				costs[column + 1] = next_costs[column]
			}
		}
		mut minimum := costs[1]
		for column in 1 .. n {
			if costs[column + 1] < minimum { minimum = costs[column + 1] }
		}
		return i64(minimum) - 100 * i64(n)
	}
}
