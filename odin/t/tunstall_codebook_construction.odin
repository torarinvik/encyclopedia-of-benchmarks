package tunstall_codebook_construction

import "core:c"

MAX_S :: i64(4222124650659840)
RESULT_FACTOR :: MAX_S + 1

@(export)
tunstall_codebook_construction :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 7 do return -1
	if input[0] < 2 || input[0] > 4 || input[1] < 2 || input[1] > 4 do return -1
	k, bits := int(input[0]), int(input[1])
	if length != c.size_t(k+2) do return -1
	var weights: [4]i64
	total: i64 = 0
	for i := 0; i < k; i += 1 {
		weight := input[2+i]
		if weight <= 0 || weight > 8 do return -1
		weights[i] = weight
		total += weight
	}
	if total > 8 do return -1

	var powers: [17]i64
	powers[0] = 1
	for i := 1; i <= 16; i += 1 { powers[i] = powers[i-1] * total }
	cap := 1
	for bit := 0; bit < bits; bit += 1 { cap *= 2 }
	target := cap
	for (target-1) % (k-1) != 0 { target -= 1 }

	var products: [31]i64
	var depths: [31]int
	var phrase_keys: [31]u64
	var leaves: [16]int
	node_count, leaf_count := 1, 0
	for symbol := 0; symbol < k; symbol += 1 {
		node := node_count
		node_count += 1
		products[node] = weights[symbol]
		depths[node] = 1
		phrase_keys[node] = u64(symbol+1) << 56
		leaves[leaf_count] = node
		leaf_count += 1
	}

	scaled_expectation := powers[16]
	for leaf_count < target {
		best_position, best_node := 0, leaves[0]
		best_probability := products[best_node] * powers[15-depths[best_node]]
		for position := 1; position < leaf_count; position += 1 {
			candidate := leaves[position]
			probability := products[candidate] * powers[15-depths[candidate]]
			if probability > best_probability || (probability == best_probability && phrase_keys[candidate] < phrase_keys[best_node]) {
				best_position, best_node, best_probability = position, candidate, probability
			}
		}

		scaled_expectation += products[best_node] * powers[16-depths[best_node]]
		leaf_count -= 1
		leaves[best_position] = leaves[leaf_count]
		for symbol := 0; symbol < k; symbol += 1 {
			child := node_count
			node_count += 1
			products[child] = products[best_node] * weights[symbol]
			depths[child] = depths[best_node] + 1
			shift := 4 * (14-depths[best_node])
			phrase_keys[child] = phrase_keys[best_node] | (u64(symbol+1) << u64(shift))
			leaves[leaf_count] = child
			leaf_count += 1
		}
	}
	if scaled_expectation > MAX_S do return -1
	return i64(target)*RESULT_FACTOR + scaled_expectation
}
