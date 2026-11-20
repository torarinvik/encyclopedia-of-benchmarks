const max_target = 127
const max_input_length = 2

@[export: 'race_car_minimum_instruction_count']
pub fn race_car_minimum_instruction_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		if length != 1 { return -1 }
		target_value := input[0]
		if target_value < 0 || target_value > max_target { return -1 }
		target := int(target_value)
		mut distance := [128]i32{}

		for position in 1 .. target + 1 {
			mut run := 0
			mut upper_power := 1
			for upper_power <= position {
				upper_power *= 2
				run += 1
			}
			upper := upper_power - 1
			if position == upper {
				distance[position] = i32(run)
				continue
			}

			mut best := i32(run + 1) + distance[upper - position]
			lower := upper_power / 2 - 1
			mut backward_run := 0
			mut backward_power := 1
			for backward_run + 1 < run {
				backward_distance := backward_power - 1
				remaining := position - (lower - backward_distance)
				candidate := i32(run + backward_run + 1) + distance[remaining]
				if candidate < best { best = candidate }
				backward_power *= 2
				backward_run += 1
			}
			distance[position] = best
		}
		return i64(distance[target])
	}
}
