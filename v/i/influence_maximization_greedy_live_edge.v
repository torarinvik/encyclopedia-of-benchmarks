module influence_maximization_greedy_live_edge

const max_n = 8
const max_m = 24
const max_worlds = 8

fn put_i64_le(mut output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

fn reachable_count(n int, m int, world int, seeds u16, edge_u [max_m]int,
		edge_v [max_m]int, masks [max_m]int) int {
	mut reached := seeds
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 0
	for vertex in 0 .. n {
		if seeds & (u16(1) << vertex) != 0 {
			queue[tail] = vertex
			tail++
		}
	}
	for head < tail {
		source := queue[head]
		head++
		for edge in 0 .. m {
			target := edge_v[edge]
			bit := u16(1) << target
			if edge_u[edge] == source && (masks[edge] & (1 << world)) != 0 && (reached & bit) == 0 {
				reached |= bit
				queue[tail] = target
				tail++
			}
		}
	}
	mut count := 0
	for vertex in 0 .. n {
		if (reached & (u16(1) << vertex)) != 0 { count++ }
	}
	return count
}

@[export: 'influence_maximization_greedy_live_edge']
pub fn influence_maximization_greedy_live_edge(input &i64, length usize,
		mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > 77 { return -1 }
	n0 := unsafe { input[0] }
	m0 := unsafe { input[1] }
	k0 := unsafe { input[2] }
	worlds0 := unsafe { input[3] }
	if n0 < 1 || n0 > 8 || m0 < 0 || m0 > 24 || k0 < 0 || k0 > n0 || worlds0 < 1 || worlds0 > 8 { return -1 }
	n, m, k, worlds := int(n0), int(m0), int(k0), int(worlds0)
	if length != usize(4 + 3 * m) { return -1 }
	mut edge_u := [max_m]int{}
	mut edge_v := [max_m]int{}
	mut masks := [max_m]int{}
	allowed := (1 << worlds) - 1
	for edge in 0 .. m {
		u := unsafe { input[4 + 3 * edge] }
		v := unsafe { input[5 + 3 * edge] }
		mask := unsafe { input[6 + 3 * edge] }
		if u < 0 || u >= n0 || v < 0 || v >= n0 || u == v || mask < 0 || mask > i64(allowed) { return -1 }
		for earlier in 0 .. edge {
			if edge_u[earlier] == int(u) && edge_v[earlier] == int(v) { return -1 }
		}
		edge_u[edge], edge_v[edge], masks[edge] = int(u), int(v), int(mask)
	}
	mut selected := u16(0)
	mut chosen := [max_n]int{}
	mut scores := [max_n]int{}
	for round in 0 .. k {
		mut current := [max_worlds]int{}
		for world in 0 .. worlds { current[world] = reachable_count(n, m, world, selected, edge_u, edge_v, masks) }
		mut best_node := -1
		mut best_score := -1
		for candidate in 0 .. n {
			bit := u16(1) << candidate
			if (selected & bit) != 0 { continue }
			mut score := 0
			for world in 0 .. worlds {
				score += reachable_count(n, m, world, selected | bit, edge_u, edge_v, masks) - current[world]
			}
			if score > best_score { best_node, best_score = candidate, score }
		}
		if best_node < 0 { return -1 }
		selected |= u16(1) << best_node
		chosen[round], scores[round] = best_node, best_score
	}
	bytes := (1 + 2 * k) * 8
	if output == nil || capacity < usize(bytes) { return -2 }
	put_i64_le(mut output, 0, i64(k))
	for round in 0 .. k {
		put_i64_le(mut output, 1 + 2 * round, i64(chosen[round]))
		put_i64_le(mut output, 2 + 2 * round, i64(scores[round]))
	}
	return i64(bytes)
}
