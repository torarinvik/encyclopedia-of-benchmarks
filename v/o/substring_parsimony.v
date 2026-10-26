module substring_parsimony

const max_states = 4
const max_input = 26
const max_assignments = 1024
const max_output_words = 2 + 5 * max_assignments
const inf = i64(1000000)

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

pub fn substring_parsimony(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == unsafe { nil } || length < 10 || length > max_input { return -1 }
	q_raw := input[0]
	threshold := input[1]
	if q_raw < 1 || q_raw > max_states || threshold < 0 || threshold > 36 { return -1 }
	q := int(q_raw)
	if length != usize(9 + q * q) { return -1 }
	mut child := [2][2]i64{}
	child[0][0] = input[2]; child[0][1] = input[3]
	child[1][0] = input[4]; child[1][1] = input[5]
	for node in 0 .. 2 {
		if child[node][0] < 1 || child[node][0] > 4 || child[node][1] < 1 || child[node][1] > 4
			|| child[node][0] == child[node][1] { return -1 }
	}
	mut root_leaf := i64(-1)
	if child[0][0] == 1 { root_leaf = child[0][1] } else if child[0][1] == 1 { root_leaf = child[0][0] }
	if root_leaf < 2 || root_leaf > 4 { return -1 }
	if child[1][0] < 2 || child[1][0] > 4 || child[1][1] < 2 || child[1][1] > 4
		|| child[1][0] == child[1][1] || child[1][0] == root_leaf || child[1][1] == root_leaf { return -1 }
	for leaf in 2 .. 5 {
		if i64(leaf) != root_leaf && child[1][0] != i64(leaf) && child[1][1] != i64(leaf) { return -1 }
	}
	mut masks := [3]i64{}
	for leaf in 0 .. 3 { masks[leaf] = input[6 + leaf] }
	universe := (u64(1) << u64(q)) - 1
	for leaf in 0 .. 3 { if masks[leaf] <= 0 || u64(masks[leaf]) > universe { return -1 } }
	mut distance := [max_states][max_states]i64{}
	for i in 0 .. q {
		for j in 0 .. q {
			value := input[9 + i * q + j]
			if value < 0 || value > 9 || (i == j && value != 0) || (i != j && value == 0) { return -1 }
			distance[i][j] = value
			if value != input[9 + j * q + i] { return -1 }
		}
	}
	for i in 0 .. q {
		for j in 0 .. q {
			for k in 0 .. q { if distance[i][k] > distance[i][j] + distance[j][k] { return -1 } }
		}
	}
	mut dp := [5][max_states]i64{}
	for node in 0 .. 5 { for state in 0 .. q { dp[node][state] = inf } }
	for leaf in 2 .. 5 {
		for state in 0 .. q {
			if (u64(masks[leaf - 2]) & (u64(1) << u64(state))) != 0 { dp[leaf][state] = 0 }
		}
	}
	mut node := 2
	for node > 0 {
		node--
		for state in 0 .. q {
			mut total := i64(0)
			for slot in 0 .. 2 {
				descendant := int(child[node][slot])
				mut best := inf
				for other in 0 .. q {
					candidate := dp[descendant][other] + distance[state][other]
					if candidate < best { best = candidate }
				}
				total += best
			}
			dp[node][state] = total
		}
	}
	mut optimum := inf
	for state in 0 .. q { if dp[0][state] < optimum { optimum = dp[0][state] } }
	if optimum >= inf { return -1 }
	mut staged := [max_output_words]i64{}
	staged[0] = optimum
	mut words := 2
	if optimum <= threshold {
		for x0 in 0 .. q {
			for x1 in 0 .. q {
				for x2 in 0 .. q {
					if (u64(masks[0]) & (u64(1) << u64(x2))) == 0 { continue }
					for x3 in 0 .. q {
						if (u64(masks[1]) & (u64(1) << u64(x3))) == 0 { continue }
						for x4 in 0 .. q {
							if (u64(masks[2]) & (u64(1) << u64(x4))) == 0 { continue }
							label := [5]int{x0, x1, x2, x3, x4}
							mut score := i64(0)
							for n in 0 .. 2 { for slot in 0 .. 2 { score += distance[label[n]][int(child[n][slot])] } }
							if score == optimum {
								for n in 0 .. 5 { staged[words] = i64(label[n]); words++ }
							}
						}
					}
				}
			}
		}
	}
	staged[1] = i64((words - 2) / 5)
	bytes := words * 8
	if output == unsafe { nil } || capacity < usize(bytes) { return -2 }
	for word in 0 .. words {
		bits := u64(staged[word])
		for byte in 0 .. 8 { output[word * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
	}
	return i64(bytes)
}
