module list_ranking_random_mate

const max_n = 8
const max_rounds = 32
const max_input = 275
const max_output = 64

@[export: 'list_ranking_random_mate']
pub fn list_ranking_random_mate(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		n64, head64 := input[0], input[1]
		if n64 < 1 || n64 > max_n || head64 < 0 || head64 >= n64 { return -1 }
		n, head := int(n64), int(head64)
		if length < usize(3 + 2*n) { return -1 }
		rounds64 := input[2 + 2*n]
		if rounds64 < 0 || rounds64 > max_rounds || length != usize(3 + 2*n64 + rounds64*n64) { return -1 }
		rounds := int(rounds64)
		mut weight := [max_n]i64{init: 0}
		mut successor := [max_n]i64{init: 0}
		mut indegree := [max_n]int{init: 0}
		mut tails := 0
		for index in 0 .. n {
			weight[index] = input[2 + index]
			successor[index] = input[2 + n + index]
			if weight[index] < 1 || weight[index] > 10000 || successor[index] < -1 || successor[index] >= n64 { return -1 }
			if successor[index] == -1 { tails++ } else {
				target := int(successor[index])
				indegree[target]++
				if indegree[target] > 1 { return -1 }
			}
		}
		if tails != 1 || indegree[head] != 0 { return -1 }
		coin_start := 3 + 2*n
		for index in 0 .. rounds*n {
			coin := input[coin_start + index]
			if coin < 0 || coin > 1 { return -1 }
		}

		mut seen := [max_n]bool{init: false}
		mut path_length := 0
		mut node := head64
		for node != -1 {
			index := int(node)
			if seen[index] || path_length == n { return -1 }
			seen[index] = true
			path_length++
			node = successor[index]
		}
		if path_length != n { return -1 }

		mut active := [max_n]bool{init: false}
		mut removal_round := [max_n]int{init: -1}
		for index in 0 .. n { active[index] = true }
		for round in 0 .. rounds {
			if successor[head] == -1 { break }
			old_successor := successor
			old_weight := weight
			mut remove := [max_n]bool{init: false}
			coin_offset := coin_start + round*n
			for index in 0 .. n {
				target_value := old_successor[index]
				if active[index] && target_value != -1 && input[coin_offset + index] == 0 &&
					input[coin_offset + int(target_value)] == 1 {
					target := int(target_value)
					remove[target] = true
					removal_round[target] = round
				}
			}
			for index in 0 .. n {
				target_value := old_successor[index]
				if active[index] && target_value != -1 && remove[int(target_value)] {
					target := int(target_value)
					weight[index] = old_weight[index] + old_weight[target]
					successor[index] = old_successor[target]
				}
			}
			for index in 0 .. n { if remove[index] { active[index] = false } }
		}
		if successor[head] != -1 { return -1 }

		mut rank := weight
		for index in 0 .. n { rank[index] = weight[index] }
		for remaining in 0 .. rounds {
			round := rounds - 1 - remaining
			for index in 0 .. n {
				if removal_round[index] == round && successor[index] != -1 { rank[index] += rank[int(successor[index])] }
			}
		}
		output_bytes := 8*n
		if output == nil || capacity < output_bytes { return -2 }
		mut staged := [max_output]u8{init: 0}
		for index in 0 .. n {
			bits := u64(rank[index])
			for byte in 0 .. 8 { staged[8*index + byte] = u8((bits >> (8*byte)) & 255) }
		}
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
