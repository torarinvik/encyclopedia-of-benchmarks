package race_car_minimum_instruction_count

import "core:c"

MAX_TARGET :: 127
MAX_INPUT_LENGTH :: 2

@(export)
race_car_minimum_instruction_count :: proc "c" (
	input: [^]i64, length: c.size_t,
) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	if length != 1 do return -1
	target_value := input[0]
	if target_value < 0 || target_value > MAX_TARGET do return -1
	target := int(target_value)
	distance: [128]i32
	distance[0] = 0

	for position := 1; position <= target; position += 1 {
		run := 0
		upper_power := 1
		for upper_power <= position {
			upper_power *= 2
			run += 1
		}
		upper := upper_power - 1
		if position == upper {
			distance[position] = i32(run)
			continue
		}

		best := i32(run + 1) + distance[upper-position]
		lower := upper_power / 2 - 1
		backward_run := 0
		backward_power := 1
		for backward_run + 1 < run {
			backward_distance := backward_power - 1
			remaining := position - (lower - backward_distance)
			candidate := i32(run + backward_run + 1) + distance[remaining]
			if candidate < best do best = candidate
			backward_power *= 2
			backward_run += 1
		}
		distance[position] = best
	}
	return i64(distance[target])
}
