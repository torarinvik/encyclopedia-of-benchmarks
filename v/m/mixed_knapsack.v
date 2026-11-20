module mixed_knapsack

const max_types = 16
const max_capacity = 64
const max_input = 67

@[export: 'mixed_knapsack']
pub fn mixed_knapsack(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	type_count_value, capacity_value := input[0], input[1]
	if type_count_value < 0 || type_count_value > max_types || capacity_value < 0 || capacity_value > max_capacity { return -1 }
	type_count, capacity := int(type_count_value), int(capacity_value)
	if length != usize(2 + 4 * type_count) { return -1 }
	for item in 0 .. type_count {
		mode, weight := input[2 + 4 * item], input[3 + 4 * item]
		value, limit := input[4 + 4 * item], input[5 + 4 * item]
		if mode < 0 || mode > 2 || weight < 1 || weight > 16 || value < 0 || value > 100 { return -1 }
		if (mode == 0 && limit != 1) || (mode == 1 && limit != 0) || (mode == 2 && (limit < 0 || limit > 16)) { return -1 }
	}

	mut best := [65]i64{}
	for item in 0 .. type_count {
		mode, weight := input[2 + 4 * item], int(input[3 + 4 * item])
		value := input[4 + 4 * item]
		if mode == 0 {
			mut cap := capacity
			for cap >= weight {
				candidate := best[cap - weight] + value
				if candidate > best[cap] { best[cap] = candidate }
				if cap == weight { break }
				cap--
			}
		} else if mode == 1 {
			for cap := weight; cap <= capacity; cap++ {
				candidate := best[cap - weight] + value
				if candidate > best[cap] { best[cap] = candidate }
			}
		} else {
			mut remaining, mut bundle_size := int(input[5 + 4 * item]), 1
			for remaining > 0 {
				copies := if bundle_size < remaining { bundle_size } else { remaining }
				bundle_weight := copies * weight
				bundle_value := i64(copies) * value
				if bundle_weight <= capacity {
					mut cap := capacity
					for cap >= bundle_weight {
						candidate := best[cap - bundle_weight] + bundle_value
						if candidate > best[cap] { best[cap] = candidate }
						if cap == bundle_weight { break }
						cap--
					}
				}
				remaining -= copies
				bundle_size *= 2
			}
		}
	}
	return best[capacity]
}
