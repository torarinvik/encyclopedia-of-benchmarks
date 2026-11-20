module linear_partition_minimax

@[export: 'linear_partition_minimax']
pub fn linear_partition_minimax(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 35 { return -1 }
		if input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > input[0] { return -1 }
		n := int(input[0])
		groups := int(input[1])
		if length != usize(n + 2) { return -1 }
		mut low := i64(0)
		mut upper := i64(0)
		for i in 0 .. n {
			value := input[i + 2]
			if value < 0 || value > 1000 { return -1 }
			if value > low { low = value }
			upper += value
		}
		for low < upper {
			middle := low + (upper - low) / 2
			mut used_groups := 1
			mut current_sum := i64(0)
			mut fits := true
			for i in 0 .. n {
				value := input[i + 2]
				if current_sum + value > middle {
					used_groups++
					current_sum = value
					if used_groups > groups { fits = false; break }
				} else {
					current_sum += value
				}
			}
			if fits { upper = middle } else { low = middle + 1 }
		}
		return low
	}
}
