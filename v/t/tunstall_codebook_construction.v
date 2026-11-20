const max_s = i64(4222124650659840)
const result_factor = max_s + i64(1)

@[export: 'tunstall_codebook_construction']
pub fn tunstall_codebook_construction(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 7 { return -1 }
		if input[0] < 2 || input[0] > 4 || input[1] < 2 || input[1] > 4 { return -1 }
		k := int(input[0])
		bits := int(input[1])
		if length != usize(k + 2) { return -1 }
		mut weights := [4]i64{}
		mut total := i64(0)
		for i in 0 .. k {
			weight := input[2 + i]
			if weight <= 0 || weight > 8 { return -1 }
			weights[i] = weight
			total += weight
		}
		if total > 8 { return -1 }

		mut powers := [17]i64{}
		powers[0] = 1
		for i in 1 .. 17 { powers[i] = powers[i - 1] * total }
		mut cap := 1
		for bit in 0 .. bits { cap *= 2 }
		mut target := cap
		for (target - 1) % (k - 1) != 0 { target-- }

		mut products := [31]i64{}
		mut depths := [31]int{}
		mut phrase_keys := [31]u64{}
		mut leaves := [16]int{}
		mut node_count, mut leaf_count := 1, 0
		for symbol in 0 .. k {
			node := node_count
			node_count++
			products[node] = weights[symbol]
			depths[node] = 1
			phrase_keys[node] = u64(symbol + 1) << 56
			leaves[leaf_count] = node
			leaf_count++
		}

		mut scaled_expectation := powers[16]
		for leaf_count < target {
			mut best_position, mut best_node := 0, leaves[0]
			mut best_probability := products[best_node] * powers[15 - depths[best_node]]
			for position in 1 .. leaf_count {
				candidate := leaves[position]
				probability := products[candidate] * powers[15 - depths[candidate]]
				if probability > best_probability || (probability == best_probability && phrase_keys[candidate] < phrase_keys[best_node]) {
					best_position, best_node, best_probability = position, candidate, probability
				}
			}

			scaled_expectation += products[best_node] * powers[16 - depths[best_node]]
			leaf_count--
			leaves[best_position] = leaves[leaf_count]
			for symbol in 0 .. k {
				child := node_count
				node_count++
				products[child] = products[best_node] * weights[symbol]
				depths[child] = depths[best_node] + 1
				shift := 4 * (14 - depths[best_node])
				phrase_keys[child] = phrase_keys[best_node] | (u64(symbol + 1) << shift)
				leaves[leaf_count] = child
				leaf_count++
			}
		}
		if scaled_expectation > max_s { return -1 }
		return i64(target) * result_factor + scaled_expectation
	}
}
