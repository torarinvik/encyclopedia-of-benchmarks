package substring_parsimony

import "core:c"

MAX_STATES :: 4
MAX_INPUT :: 26
MAX_ASSIGNMENTS :: 1024
MAX_OUTPUT_WORDS :: 2 + 5 * MAX_ASSIGNMENTS
INF :: i64(1_000_000)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

substring_parsimony :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 10 || length > MAX_INPUT do return -1
	q_raw := input[0]
	threshold := input[1]
	if q_raw < 1 || q_raw > MAX_STATES || threshold < 0 || threshold > 36 do return -1
	q := int(q_raw)
	if length != c.size_t(9 + q * q) do return -1
	child: [2][2]i64 = {{input[2], input[3]}, {input[4], input[5]}}
	for node := 0; node < 2; node += 1 {
		if child[node][0] < 1 || child[node][0] > 4 || child[node][1] < 1 || child[node][1] > 4
			|| child[node][0] == child[node][1] do return -1
	}
	root_leaf: i64 = -1
	if child[0][0] == 1 { root_leaf = child[0][1] } else if child[0][1] == 1 { root_leaf = child[0][0] }
	if root_leaf < 2 || root_leaf > 4 do return -1
	if child[1][0] < 2 || child[1][0] > 4 || child[1][1] < 2 || child[1][1] > 4
		|| child[1][0] == child[1][1] || child[1][0] == root_leaf || child[1][1] == root_leaf do return -1
	for leaf := 2; leaf < 5; leaf += 1 {
		if i64(leaf) != root_leaf && child[1][0] != i64(leaf) && child[1][1] != i64(leaf) do return -1
	}
	masks: [3]i64 = {input[6], input[7], input[8]}
	universe := (u64(1) << u64(q)) - 1
	for leaf := 0; leaf < 3; leaf += 1 {
		if masks[leaf] <= 0 || u64(masks[leaf]) > universe do return -1
	}
	distance: [MAX_STATES][MAX_STATES]i64
	for i := 0; i < q; i += 1 {
		for j := 0; j < q; j += 1 {
			value := input[9 + i * q + j]
			if value < 0 || value > 9 || (i == j && value != 0) || (i != j && value == 0) do return -1
			distance[i][j] = value
			if value != input[9 + j * q + i] do return -1
		}
	}
	for i := 0; i < q; i += 1 {
		for j := 0; j < q; j += 1 {
			for k := 0; k < q; k += 1 {
				if distance[i][k] > distance[i][j] + distance[j][k] do return -1
			}
		}
	}
	dp: [5][MAX_STATES]i64
	for node := 0; node < 5; node += 1 {
		for state := 0; state < q; state += 1 { dp[node][state] = INF }
	}
	for leaf := 2; leaf < 5; leaf += 1 {
		for state := 0; state < q; state += 1 {
			if (u64(masks[leaf - 2]) & (u64(1) << u64(state))) != 0 do dp[leaf][state] = 0
		}
	}
	for node := 1; node >= 0; node -= 1 {
		for state := 0; state < q; state += 1 {
			total: i64 = 0
			for slot := 0; slot < 2; slot += 1 {
				descendant := int(child[node][slot])
				best := INF
				for other := 0; other < q; other += 1 {
					candidate := dp[descendant][other] + distance[state][other]
					if candidate < best { best = candidate }
				}
				total += best
			}
			dp[node][state] = total
		}
	}
	optimum := INF
	for state := 0; state < q; state += 1 { if dp[0][state] < optimum { optimum = dp[0][state] } }
	if optimum >= INF do return -1
	staged: [MAX_OUTPUT_WORDS]i64
	staged[0] = optimum
	words := 2
	if optimum <= threshold {
		for x0 := 0; x0 < q; x0 += 1 {
			for x1 := 0; x1 < q; x1 += 1 {
				for x2 := 0; x2 < q; x2 += 1 {
					if (u64(masks[0]) & (u64(1) << u64(x2))) == 0 do continue
					for x3 := 0; x3 < q; x3 += 1 {
						if (u64(masks[1]) & (u64(1) << u64(x3))) == 0 do continue
						for x4 := 0; x4 < q; x4 += 1 {
							if (u64(masks[2]) & (u64(1) << u64(x4))) == 0 do continue
							label := [5]int{x0, x1, x2, x3, x4}
							score: i64 = 0
							for node := 0; node < 2; node += 1 {
								for slot := 0; slot < 2; slot += 1 {
									score += distance[label[node]][int(child[node][slot])]
								}
							}
							if score == optimum {
								for node := 0; node < 5; node += 1 { staged[words] = i64(label[node]); words += 1 }
							}
						}
					}
				}
			}
		}
	}
	staged[1] = i64((words - 2) / 5)
	bytes := words * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for word := 0; word < words; word += 1 { store_i64_le(output, word * 8, staged[word]) }
	return i64(bytes)
}
