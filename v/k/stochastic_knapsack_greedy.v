module stochastic_knapsack_greedy

const max_items = 5
const max_atoms = 3
const max_input = 43
const max_output_words = 9

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'stochastic_knapsack_greedy']
pub fn stochastic_knapsack_greedy(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n_raw, bound_raw := input[0], input[1]
		if n_raw < 1 || n_raw > max_items || bound_raw < 1 || bound_raw > 8 { return -1 }
		n, bound := int(n_raw), int(bound_raw)
		mut rewards := [max_items]i64{init: 0}
		mut atom_counts := [max_items]int{init: 0}
		mut denominators := [max_items]i64{init: 0}
		mut fits := [max_items]i64{init: 0}
		mut means := [max_items]i64{init: 0}
		mut sizes := [max_items][max_atoms]i64{init: 0}
		mut weights := [max_items][max_atoms]i64{init: 0}
		mut position := 2
		for item in 0 .. n {
			if position + 2 > int(length) { return -1 }
			reward, atom_count_raw := input[position], input[position + 1]
			position += 2
			if reward < 0 || reward > 20 || atom_count_raw < 1 || atom_count_raw > max_atoms { return -1 }
			rewards[item] = reward
			atom_counts[item] = int(atom_count_raw)
			for atom in 0 .. atom_counts[item] {
				if position + 2 > int(length) { return -1 }
				size, weight := input[position], input[position + 1]
				position += 2
				if size < 0 || size > bound + 1 || weight < 1 || weight > 3 { return -1 }
				sizes[item][atom], weights[item][atom] = size, weight
				denominators[item] += weight
				if size <= bound { fits[item] += weight }
				means[item] += (if size < bound { size } else { bound }) * weight
			}
			if denominators[item] > 9 || means[item] == 0 { return -1 }
		}
		if position != int(length) { return -1 }

		mut order := [max_items]int{init: 0}
		for i in 0 .. n {
			mut j := i
			for j > 0 {
				previous := order[j - 1]
				left_score := rewards[i] * fits[i] * means[previous]
				right_score := rewards[previous] * fits[previous] * means[i]
				before := left_score > right_score || (left_score == right_score && i < previous)
				if !before { break }
				order[j] = previous
				j--
			}
			order[j] = i
		}
		mut best_single := 0
		for i in 1 .. n {
			left_score := rewards[i] * fits[i] * denominators[best_single]
			right_score := rewards[best_single] * fits[best_single] * denominators[i]
			if left_score > right_score { best_single = i }
		}
		mut joint_denominator := i64(1)
		mut scenario_count := 1
		for i in 0 .. n {
			joint_denominator *= denominators[i]
			scenario_count *= atom_counts[i]
		}
		mut singleton_score, mut order_score := i64(0), i64(0)
		for scenario in 0 .. scenario_count {
			mut digits, mut scenario_weight := scenario, i64(1)
			mut selected_size := [max_items]i64{init: 0}
			for item in 0 .. n {
				atom := digits % atom_counts[item]
				digits /= atom_counts[item]
				selected_size[item] = sizes[item][atom]
				scenario_weight *= weights[item][atom]
			}
			if selected_size[best_single] <= bound { singleton_score += scenario_weight * rewards[best_single] }
			mut used, mut earned := 0, i64(0)
			for rank in 0 .. n {
				item := order[rank]
				if used + int(selected_size[item]) > bound { break }
				used += int(selected_size[item])
				earned += rewards[item]
			}
			order_score += scenario_weight * earned
		}

		use_order := order_score > singleton_score
		output_count := if use_order { n } else { 1 }
		mut staged := [max_output_words]i64{init: 0}
		staged[0] = if use_order { 1 } else { 0 }
		staged[1] = i64(output_count)
		for i in 0 .. output_count { staged[2 + i] = i64(if use_order { order[i] } else { best_single }) }
		staged[2 + output_count] = if use_order { order_score } else { singleton_score }
		staged[3 + output_count] = joint_denominator
		words := output_count + 4
		bytes := words * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		for word in 0 .. words { store_i64_le(mut output[..], word * 8, staged[word]) }
		return i64(bytes)
	}
}
