module k_ary_huffman_weighted_path_cost

@[export: 'k_ary_huffman_weighted_path_cost']
pub fn k_ary_huffman_weighted_path_cost(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 13 { return -1 }
		arity_value := input[0]
		count_value := input[1]
		if (arity_value != 3 && arity_value != 4) || count_value < 1 || count_value > 10 { return -1 }
		arity := int(arity_value)
		count := int(count_value)
		if length != usize(count + 2) || (count > 1 && (count - 1) % (arity - 1) != 0) { return -1 }

		mut weights := [16]i64{}
		mut active := [16]bool{}
		for index in 0 .. count {
			weight := input[index + 2]
			if weight < 0 || weight > 1000 { return -1 }
			weights[index] = weight
			active[index] = true
		}

		mut node_count := count
		mut active_count := count
		mut cost := i64(0)
		for active_count > 1 {
			mut combined := i64(0)
			for pick in 0 .. arity {
				mut best := -1
				for index in 0 .. node_count {
					if !active[index] { continue }
					if best == -1 {
						best = index
					} else if weights[index] < weights[best] || (weights[index] == weights[best] && index < best) {
						best = index
					}
				}
				if best == -1 { return -1 }
				combined += weights[best]
				active[best] = false
				active_count--
			}
			cost += combined
			weights[node_count] = combined
			active[node_count] = true
			node_count++
			active_count++
		}
		return cost
	}
}
