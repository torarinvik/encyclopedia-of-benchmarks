package stochastic_knapsack_greedy

import "core:c"

MAX_ITEMS :: 5
MAX_ATOMS :: 3
MAX_INPUT :: 43
MAX_OUTPUT_WORDS :: 9

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

stochastic_knapsack_greedy :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_raw, bound_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_ITEMS || bound_raw < 1 || bound_raw > 8 do return -1
	n, bound := int(n_raw), int(bound_raw)
	rewards: [MAX_ITEMS]i64
	atom_counts: [MAX_ITEMS]int
	denominators: [MAX_ITEMS]i64
	fits: [MAX_ITEMS]i64
	means: [MAX_ITEMS]i64
	sizes: [MAX_ITEMS][MAX_ATOMS]i64
	weights: [MAX_ITEMS][MAX_ATOMS]i64
	position := 2
	for item := 0; item < n; item += 1 {
		if position + 2 > int(length) do return -1
		reward, atom_count_raw := input[position], input[position + 1]
		position += 2
		if reward < 0 || reward > 20 || atom_count_raw < 1 || atom_count_raw > MAX_ATOMS do return -1
		rewards[item] = reward
		atom_counts[item] = int(atom_count_raw)
		for atom := 0; atom < atom_counts[item]; atom += 1 {
			if position + 2 > int(length) do return -1
			size, weight := input[position], input[position + 1]
			position += 2
			if size < 0 || size > bound + 1 || weight < 1 || weight > 3 do return -1
			sizes[item][atom] = size
			weights[item][atom] = weight
			denominators[item] += weight
			if size <= bound do fits[item] += weight
			capped := size
			if capped > bound do capped = bound
			means[item] += capped * weight
		}
		if denominators[item] > 9 || means[item] == 0 do return -1
	}
	if position != int(length) do return -1

	order: [MAX_ITEMS]int
	for i := 0; i < n; i += 1 {
		j := i
		for j > 0 {
			previous := order[j - 1]
			left_score := rewards[i] * fits[i] * means[previous]
			right_score := rewards[previous] * fits[previous] * means[i]
			before := left_score > right_score || (left_score == right_score && i < previous)
			if !before do break
			order[j] = previous
			j -= 1
		}
		order[j] = i
	}
	best_single := 0
	for i := 1; i < n; i += 1 {
		left_score := rewards[i] * fits[i] * denominators[best_single]
		right_score := rewards[best_single] * fits[best_single] * denominators[i]
		if left_score > right_score do best_single = i
	}
	joint_denominator: i64 = 1
	scenario_count := 1
	for i := 0; i < n; i += 1 {
		joint_denominator *= denominators[i]
		scenario_count *= atom_counts[i]
	}
	var singleton_score, order_score: i64
	for scenario := 0; scenario < scenario_count; scenario += 1 {
		digits, scenario_weight := scenario, i64(1)
		selected_size: [MAX_ITEMS]i64
		for item := 0; item < n; item += 1 {
			atom := digits % atom_counts[item]
			digits /= atom_counts[item]
			selected_size[item] = sizes[item][atom]
			scenario_weight *= weights[item][atom]
		}
		if selected_size[best_single] <= bound do singleton_score += scenario_weight * rewards[best_single]
		used, earned := 0, i64(0)
		for rank := 0; rank < n; rank += 1 {
			item := order[rank]
			if used + int(selected_size[item]) > bound do break
			used += int(selected_size[item])
			earned += rewards[item]
		}
		order_score += scenario_weight * earned
	}

	use_order := order_score > singleton_score
	output_count := 1
	if use_order do output_count = n
	staged: [MAX_OUTPUT_WORDS]i64
	staged[0] = 0
	if use_order do staged[0] = 1
	staged[1] = i64(output_count)
	for i := 0; i < output_count; i += 1 {
		selected := best_single
		if use_order do selected = order[i]
		staged[2 + i] = i64(selected)
	}
	if use_order { staged[2 + output_count] = order_score } else { staged[2 + output_count] = singleton_score }
	staged[3 + output_count] = joint_denominator
	words := output_count + 4
	bytes := words * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for word := 0; word < words; word += 1 { store_i64_le(output, word * 8, staged[word]) }
	return i64(bytes)
}
