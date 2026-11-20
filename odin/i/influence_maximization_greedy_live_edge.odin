package influence_maximization_greedy_live_edge

import "core:c"

MAX_N :: 8
MAX_M :: 24
MAX_WORLDS :: 8

put_i64 :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[word*8+byte] = u8((bits >> (8*byte)) & 255)
	}
}

reachable_count :: proc "contextless" (n, m, world: int, seeds: u16,
		edge_u, edge_v, masks: [MAX_M]int) -> int {
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
		for edge := 0; edge < m; edge += 1 {
			target := edge_v[edge]
			bit := u16(1) << target
			if edge_u[edge] == source && masks[edge] & (1 << world) != 0 && reached & bit == 0 {
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
	return count
}

@(export)
influence_maximization_greedy_live_edge :: proc "c" (input: [^]i64,
		input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 4 || input_length > 77 do return -1
	n0, m0, k0, worlds0 := input[0], input[1], input[2], input[3]
	if n0 < 1 || n0 > 8 || m0 < 0 || m0 > 24 || k0 < 0 || k0 > n0 || worlds0 < 1 || worlds0 > 8 do return -1
	n, m, k, worlds := int(n0), int(m0), int(k0), int(worlds0)
	if input_length != c.size_t(4+3*m) do return -1
	edge_u, edge_v, masks: [MAX_M]int = {}
	allowed := (1 << worlds) - 1
	for edge := 0; edge < m; edge += 1 {
		u, v, mask := input[4+3*edge], input[5+3*edge], input[6+3*edge]
		if u < 0 || u >= n0 || v < 0 || v >= n0 || u == v || mask < 0 || mask > i64(allowed) do return -1
		for earlier := 0; earlier < edge; earlier += 1 {
			if edge_u[earlier] == int(u) && edge_v[earlier] == int(v) do return -1
		}
		edge_u[edge], edge_v[edge], masks[edge] = int(u), int(v), int(mask)
	}
	selected: u16 = 0
	chosen, scores: [MAX_N]int = {}
	for round := 0; round < k; round += 1 {
		current: [MAX_WORLDS]int = {}
		for world := 0; world < worlds; world += 1 {
			current[world] = reachable_count(n, m, world, selected, edge_u, edge_v, masks)
		}
		best_node, best_score := -1, -1
		for candidate := 0; candidate < n; candidate += 1 {
			bit := u16(1) << candidate
			if selected & bit != 0 do continue
			score := 0
			for world := 0; world < worlds; world += 1 {
				score += reachable_count(n, m, world, selected|bit, edge_u, edge_v, masks)-current[world]
			}
			if score > best_score { best_node, best_score = candidate, score }
		}
		if best_node < 0 do return -1
		selected |= u16(1) << best_node
		chosen[round], scores[round] = best_node, best_score
	}
	bytes := c.size_t((1+2*k)*8)
	if output == nil || output_capacity < bytes do return -2
	put_i64(output, 0, i64(k))
	for round := 0; round < k; round += 1 {
		put_i64(output, 1+2*round, i64(chosen[round]))
		put_i64(output, 2+2*round, i64(scores[round]))
	}
	return i64(bytes)
}
