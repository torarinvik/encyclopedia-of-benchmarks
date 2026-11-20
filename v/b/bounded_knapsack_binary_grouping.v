module bounded_knapsack_binary_grouping

const max_types = 16
const max_capacity = 64
const max_input = 51

@[export: 'bounded_knapsack_binary_grouping']
pub fn bounded_knapsack_binary_grouping(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	type_count_value, capacity_value := input[0], input[1]
	if type_count_value < 0 || type_count_value > max_types || capacity_value < 0 || capacity_value > max_capacity { return -1 }
	type_count, capacity := int(type_count_value), int(capacity_value)
	if length != usize(2 + 3 * type_count) { return -1 }
	for item in 0 .. type_count {
		weight, value, count := input[2 + 3 * item], input[3 + 3 * item], input[4 + 3 * item]
		if weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16 { return -1 }
	}

	mut best := [65]i64{}
	for item in 0 .. type_count {
		weight := int(input[2 + 3 * item])
		value := input[3 + 3 * item]
		mut remaining := int(input[4 + 3 * item])
		mut bundle_size := 1
		for remaining > 0 {
			copies := if bundle_size < remaining { bundle_size } else { remaining }
			bundle_weight := weight * copies
			bundle_value := value * i64(copies)
			if bundle_weight <= capacity {
				mut limit := capacity
				for limit >= bundle_weight {
					candidate := best[limit - bundle_weight] + bundle_value
					if candidate > best[limit] { best[limit] = candidate }
					if limit == bundle_weight { break }
					limit--
				}
			}
			remaining -= copies
			bundle_size *= 2
		}
	}
	return best[capacity]
}
