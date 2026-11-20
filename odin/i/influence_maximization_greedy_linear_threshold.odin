package influence_maximization_greedy_linear_threshold

import "core:c"

MAX_N :: 8
MAX_M :: 24
MAX_WORLDS :: 8
MAX_INPUT :: 141
WEIGHT_SCALE :: 256

put_i64 :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[word*8+byte] = u8((bits >> (8*byte)) & 255)
	}
}

reachable_count :: proc "contextless" (n: int, parents: [MAX_N]int, seeds: u16) -> i64 {
	queue: [MAX_N]int = {}
	reached := seeds
	head, tail := 0, 0
	for vertex := 0; vertex < n; vertex += 1 {
		if seeds & (u16(1) << vertex) != 0 {
			queue[tail] = vertex
			tail += 1
		}
	}
	for head < tail {
		source := queue[head]
		head += 1
		for target := 0; target < n; target += 1 {
			bit := u16(1) << target
			if parents[target] == source && reached & bit == 0 {
				reached |= bit
				queue[tail] = target
				tail += 1
			}
		}
	}
	count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		if reached & (u16(1) << vertex) != 0 { count += 1 }
	}
	return i64(count)
}

@(export)
influence_maximization_greedy_linear_threshold :: proc "c" (input: [^]i64,
		input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 4 || input_length > MAX_INPUT do return -1
	n0, m0, k0, worlds0 := input[0], input[1], input[2], input[3]
	if n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > MAX_M || k0 < 0 || k0 > n0 || worlds0 < 1 || worlds0 > MAX_WORLDS do return -1
	n, m, k, worlds := int(n0), int(m0), int(k0), int(worlds0)
	if input_length != c.size_t(4+3*m+worlds*n) do return -1
	edge_u, edge_v, edge_weight: [MAX_M]int = {}
	incoming_sum: [MAX_N]int = {}
	for edge := 0; edge < m; edge += 1 {
		u, v, weight := input[4+3*edge], input[5+3*edge], input[6+3*edge]
		if u < 0 || u >= n0 || v < 0 || v >= n0 || u == v || weight < 0 || weight > WEIGHT_SCALE do return -1
		for prior := 0; prior < edge; prior += 1 {
			if edge_u[prior] == int(u) && edge_v[prior] == int(v) do return -1
		}
		edge_u[edge], edge_v[edge], edge_weight[edge] = int(u), int(v), int(weight)
		incoming_sum[int(v)] += int(weight)
		if incoming_sum[int(v)] > WEIGHT_SCALE do return -1
	}
	draws: [MAX_WORLDS][MAX_N]int = {}
	draws_start := 4+3*m
	for world := 0; world < worlds; world += 1 {
		for vertex := 0; vertex < n; vertex += 1 {
			draw := input[draws_start+world*n+vertex]
			if draw < 0 || draw >= WEIGHT_SCALE do return -1
			draws[world][vertex] = int(draw)
		}
	}
	parents: [MAX_WORLDS][MAX_N]int = {}
	for world := 0; world < worlds; world += 1 {
		for target := 0; target < n; target += 1 {
			parents[world][target] = -1
			ticket := draws[world][target]
			offset := 0
			for edge := 0; edge < m; edge += 1 {
				if edge_v[edge] != target do continue
				next_offset := offset+edge_weight[edge]
				if offset <= ticket && ticket < next_offset {
					parents[world][target] = edge_u[edge]
					break
				}
				offset = next_offset
			}
		}
	}
	chosen, scores: [MAX_N]i64 = {}
	selected: u16 = 0
	for round := 0; round < k; round += 1 {
		current: [MAX_WORLDS]i64 = {}
		for world := 0; world < worlds; world += 1 {
			current[world] = reachable_count(n, parents[world], selected)
		}
		best_node, best_score := -1, i64(-1)
		for candidate := 0; candidate < n; candidate += 1 {
			bit := u16(1) << candidate
			if selected & bit != 0 do continue
			score: i64 = 0
			for world := 0; world < worlds; world += 1 {
				score += reachable_count(n, parents[world], selected|bit)-current[world]
			}
			if score > best_score { best_node, best_score = candidate, score }
		}
		if best_node < 0 do return -1
		selected |= u16(1) << best_node
		chosen[round], scores[round] = i64(best_node), best_score
	}
	bytes := c.size_t(8*(1+2*k))
	if output == nil || output_capacity < bytes do return -2
	put_i64(output, 0, i64(k))
	for round := 0; round < k; round += 1 {
		put_i64(output, 1+2*round, chosen[round])
		put_i64(output, 2+2*round, scores[round])
	}
	return i64(bytes)
}
