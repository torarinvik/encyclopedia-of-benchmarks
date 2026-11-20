module random_permutation_cycle_cap_count

@[export: 'random_permutation_cycle_cap_count']
pub fn random_permutation_cycle_cap_count(input &i64, input_length usize) i64 {
	unsafe {
		if input == nil || input_length != 2 { return -1 }
		n := input[0]
		cap := input[1]
		if n < 1 || n > 20 || cap < 1 || cap > n { return -1 }

		mut counts := [21]i64{}
		counts[0] = 1
		for size in 1 .. int(n) + 1 {
			mut total := i64(0)
			mut cycle_choices := i64(1)
			limit := size
			if int(cap) < limit { limit = int(cap) }
			for cycle_length in 1 .. limit + 1 {
				if cycle_length > 1 { cycle_choices *= i64(size - cycle_length + 1) }
				total += cycle_choices * counts[size - cycle_length]
			}
			counts[size] = total
		}
		return counts[int(n)]
	}
}
