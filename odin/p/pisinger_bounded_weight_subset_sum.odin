package pisinger_bounded_weight_subset_sum

import "core:c"

MAX_ITEMS :: 32
MAX_TARGET :: 256
MAX_WEIGHT :: 12
MAX_PARSEABLE_INPUT_LENGTH :: 35
MAX_STATES :: 2 * MAX_WEIGHT

@(export)
pisinger_bounded_weight_subset_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value := input[0]
	target_value := input[1]
	if n_value < 0 || n_value > MAX_ITEMS || target_value < 0 || target_value > MAX_TARGET do return -1
	n := int(n_value)
	if int(length) != n + 2 do return -1

	width: i32 = 0
	for index := 0; index < n; index += 1 {
		weight := input[index + 2]
		if weight < 1 || weight > MAX_WEIGHT do return -1
		if weight > i64(width) do width = i32(weight)
	}
	if n == 0 do return 0

	target := i32(target_value)
	prefix_sum: i32 = 0
	break_index := 0
	for break_index < n && prefix_sum + i32(input[break_index + 2]) <= target {
		prefix_sum += i32(input[break_index + 2])
		break_index += 1
	}
	if break_index == n do return i64(prefix_sum)

	previous: [MAX_STATES]i32
	current: [MAX_STATES]i32
	for slot := 0; slot < 2 * int(width); slot += 1 { previous[slot] = -1 }
	previous[int(prefix_sum + width - target - 1)] = i32(break_index)

	for item := break_index; item < n; item += 1 {
		for slot := 0; slot < 2 * int(width); slot += 1 { current[slot] = previous[slot] }
		weight := i32(input[item + 2])
		for slot := 0; slot < int(width); slot += 1 {
			destination := slot + int(weight)
			if previous[slot] > current[destination] do current[destination] = previous[slot]
		}
		slot := 2 * int(width) - 1
		for slot >= int(width) {
			first_item := previous[slot]
			if first_item < 0 do first_item = 0
			stop_item := current[slot]
			for removed := first_item; removed < stop_item; removed += 1 {
				reduced := slot - int(input[int(removed) + 2])
				if removed > current[reduced] do current[reduced] = removed
			}
			slot -= 1
		}
		for slot := 0; slot < 2 * int(width); slot += 1 { previous[slot] = current[slot] }
	}

	low_mass := 0
	if target >= width do low_mass = target - width + 1
	mass := target
	for mass >= low_mass {
		if previous[int(mass + width - target - 1)] >= 0 do return i64(mass)
		if mass == low_mass do break
		mass -= 1
	}
	return 0
}
