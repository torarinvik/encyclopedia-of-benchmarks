package k_ary_huffman_weighted_path_cost

import "core:c"

@(export)
k_ary_huffman_weighted_path_cost :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 13 do return -1
	arity_value := input[0]
	count_value := input[1]
	if (arity_value != 3 && arity_value != 4) || count_value < 1 || count_value > 10 do return -1
	arity := int(arity_value)
	count := int(count_value)
	if length != c.size_t(count + 2) || (count > 1 && (count - 1) % (arity - 1) != 0) do return -1

	weights: [16]i64
	active: [16]bool
	for index := 0; index < 16; index += 1 { weights[index] = 0; active[index] = false }
	for index := 0; index < count; index += 1 {
		weight := input[index + 2]
		if weight < 0 || weight > 1000 do return -1
		weights[index] = weight
		active[index] = true
	}

	node_count := count
	active_count := count
	cost: i64 = 0
	for active_count > 1 {
		combined: i64 = 0
		for pick := 0; pick < arity; pick += 1 {
			best := -1
			for index := 0; index < node_count; index += 1 {
				if !active[index] do continue
				if best == -1 {
					best = index
				} else if weights[index] < weights[best] || (weights[index] == weights[best] && index < best) {
					best = index
				}
			}
			if best == -1 do return -1
			combined += weights[best]
			active[best] = false
			active_count -= 1
		}
		cost += combined
		weights[node_count] = combined
		active[node_count] = true
		node_count += 1
		active_count += 1
	}
	return cost
}
