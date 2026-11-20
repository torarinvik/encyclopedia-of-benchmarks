package mixed_knapsack

import "core:c"

MAX_TYPES :: 16
MAX_CAPACITY :: 64
MAX_INPUT :: 67

@(export)
mixed_knapsack :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	type_count_value, capacity_value := input[0], input[1]
	if type_count_value < 0 || type_count_value > MAX_TYPES || capacity_value < 0 || capacity_value > MAX_CAPACITY do return -1
	type_count, capacity := int(type_count_value), int(capacity_value)
	if int(length) != 2 + 4 * type_count do return -1
	for item := 0; item < type_count; item += 1 {
		mode, weight := input[2 + 4 * item], input[3 + 4 * item]
		value, limit := input[4 + 4 * item], input[5 + 4 * item]
		if mode < 0 || mode > 2 || weight < 1 || weight > 16 || value < 0 || value > 100 do return -1
		if (mode == 0 && limit != 1) || (mode == 1 && limit != 0) || (mode == 2 && (limit < 0 || limit > 16)) do return -1
	}

	best: [65]i64
	for cap := 0; cap <= capacity; cap += 1 { best[cap] = 0 }
	for item := 0; item < type_count; item += 1 {
		mode, weight := input[2 + 4 * item], int(input[3 + 4 * item])
		value := input[4 + 4 * item]
		if mode == 0 {
			cap := capacity
			for cap >= weight {
				candidate := best[cap - weight] + value
				if candidate > best[cap] do best[cap] = candidate
				if cap == weight do break
				cap -= 1
			}
		} else if mode == 1 {
			for cap := weight; cap <= capacity; cap += 1 {
				candidate := best[cap - weight] + value
				if candidate > best[cap] do best[cap] = candidate
			}
		} else {
			remaining, bundle_size := int(input[5 + 4 * item]), 1
			for remaining > 0 {
				copies := bundle_size
				if copies > remaining do copies = remaining
				bundle_weight := copies * weight
				bundle_value := i64(copies) * value
				if bundle_weight <= capacity {
					cap := capacity
					for cap >= bundle_weight {
						candidate := best[cap - bundle_weight] + bundle_value
						if candidate > best[cap] do best[cap] = candidate
						if cap == bundle_weight do break
						cap -= 1
					}
				}
				remaining -= copies
				bundle_size *= 2
			}
		}
	}
	return best[capacity]
}
