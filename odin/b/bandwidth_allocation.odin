package bandwidth_allocation

import "core:c"

MAX_USERS :: 64

@(export)
bandwidth_allocation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 { return -1 }
	bandwidth, count_value := input[0], input[1]
	if bandwidth < 0 || bandwidth > 100_000 || count_value < 0 || count_value > MAX_USERS { return -1 }
	count := int(count_value)
	if length != c.size_t(2 + 2 * count) { return -1 }
	for index := 0; index < count; index += 1 {
		demand, value := input[2 + index], input[2 + count + index]
		if demand < 1 || demand > 1_000 || value < 0 || value > 10_000 { return -1 }
	}

	ratios: [64]f64
	order: [64]int
	for index := 0; index < count; index += 1 {
		demand, value := input[2 + index], input[2 + count + index]
		ratios[index] = f64(value) / f64(demand)
		order[index] = index
	}
	for index := 1; index < count; index += 1 {
		key_ratio := ratios[index]
		key_index := order[index]
		position := index
		for position > 0 && ratios[position - 1] < key_ratio {
			ratios[position] = ratios[position - 1]
			order[position] = order[position - 1]
			position -= 1
		}
		ratios[position] = key_ratio
		order[position] = key_index
	}

	remaining := bandwidth
	total: i64 = 0
	for position := 0; position < count; position += 1 {
		index := order[position]
		demand, value := input[2 + index], input[2 + count + index]
		if remaining >= demand {
			total += value
			remaining -= demand
		} else {
			total += i64(ratios[position] * f64(remaining))
			break
		}
	}
	return total
}
