package bounded_knapsack_binary_grouping

import "core:c"

MAX_TYPES :: 16
MAX_CAPACITY :: 64
MAX_INPUT :: 51

@(export)
bounded_knapsack_binary_grouping :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	type_count_value, capacity_value := input[0], input[1]
	if type_count_value < 0 || type_count_value > MAX_TYPES || capacity_value < 0 || capacity_value > MAX_CAPACITY do return -1
	type_count, capacity := int(type_count_value), int(capacity_value)
	if int(length) != 2 + 3 * type_count do return -1
	for item := 0; item < type_count; item += 1 {
		weight, value, count := input[2 + 3 * item], input[3 + 3 * item], input[4 + 3 * item]
		if weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16 do return -1
	}

	best: [65]i64
	for limit := 0; limit <= capacity; limit += 1 { best[limit] = 0 }
	for item := 0; item < type_count; item += 1 {
		weight := int(input[2 + 3 * item])
		value := input[3 + 3 * item]
		remaining := int(input[4 + 3 * item])
		bundle_size := 1
		for remaining > 0 {
			copies := bundle_size
			if copies > remaining do copies = remaining
			bundle_weight := weight * copies
			bundle_value := value * i64(copies)
			if bundle_weight <= capacity {
				limit := capacity
				for limit >= bundle_weight {
					candidate := best[limit - bundle_weight] + bundle_value
					if candidate > best[limit] do best[limit] = candidate
					if limit == bundle_weight do break
					limit -= 1
				}
			}
			remaining -= copies
			bundle_size *= 2
		}
	}
	return best[capacity]
}
