module influence_maximization_greedy_linear_threshold

const max_n = 8
const max_m = 24
const max_worlds = 8
const max_input = 141
const weight_scale = 256

fn put_i64_le(mut output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

fn reachable_count(n int, parents [max_n]int, seeds u16) i64 {
	mut reached := seeds
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 0
	for vertex in 0 .. n {
		if (seeds & (u16(1) << vertex)) != 0 {
			queue[tail] = vertex
			tail++
		}
	}
	for head < tail {
		source := queue[head]
		head++
		for target in 0 .. n {
			bit := u16(1) << target
			if parents[target] == source && (reached & bit) == 0 {
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
	return i64(count)
}

@[export: 'influence_maximization_greedy_linear_threshold']
pub fn influence_maximization_greedy_linear_threshold(input &i64, length usize,
		mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > max_input { return -1 }
	n0 := unsafe { input[0] }
	m0 := unsafe { input[1] }
	k0 := unsafe { input[2] }
	worlds0 := unsafe { input[3] }
	if n0 < 1 || n0 > max_n || m0 < 0 || m0 > max_m || k0 < 0 || k0 > n0
		|| worlds0 < 1 || worlds0 > max_worlds { return -1 }
	n, m, k, worlds := int(n0), int(m0), int(k0), int(worlds0)
	if length != usize(4 + 3*m + worlds*n) { return -1 }
	mut edge_u := [max_m]int{}
	mut edge_v := [max_m]int{}
	mut edge_weight := [max_m]int{}
	mut incoming_sum := [max_n]int{}
	for edge in 0 .. m {
		u := unsafe { input[4 + 3*edge] }
		v := unsafe { input[5 + 3*edge] }
		weight := unsafe { input[6 + 3*edge] }
		if u < 0 || u >= n0 || v < 0 || v >= n0 || u == v || weight < 0 || weight > weight_scale { return -1 }
		for prior in 0 .. edge {
			if edge_u[prior] == int(u) && edge_v[prior] == int(v) { return -1 }
		}
		edge_u[edge], edge_v[edge], edge_weight[edge] = int(u), int(v), int(weight)
		incoming_sum[int(v)] += int(weight)
		if incoming_sum[int(v)] > weight_scale { return -1 }
	}
	mut draws := [max_worlds][max_n]int{}
	draws_start := 4 + 3*m
	for world in 0 .. worlds {
		for vertex in 0 .. n {
			draw := unsafe { input[draws_start + world*n + vertex] }
			if draw < 0 || draw >= weight_scale { return -1 }
			draws[world][vertex] = int(draw)
		}
	}
	mut parents := [max_worlds][max_n]int{}
	for world in 0 .. worlds {
		for target in 0 .. n {
			parents[world][target] = -1
			ticket := draws[world][target]
			mut offset := 0
			for edge in 0 .. m {
				if edge_v[edge] != target { continue }
				next_offset := offset + edge_weight[edge]
				if offset <= ticket && ticket < next_offset {
					parents[world][target] = edge_u[edge]
					break
				}
				offset = next_offset
			}
		}
	}
	mut selected := u16(0)
	mut chosen := [max_n]i64{}
	mut scores := [max_n]i64{}
	for round in 0 .. k {
		mut current := [max_worlds]i64{}
		for world in 0 .. worlds { current[world] = reachable_count(n, parents[world], selected) }
		mut best_node := -1
		mut best_score := i64(-1)
		for candidate in 0 .. n {
			bit := u16(1) << candidate
			if (selected & bit) != 0 { continue }
			mut score := i64(0)
			for world in 0 .. worlds {
				score += reachable_count(n, parents[world], selected | bit) - current[world]
			}
			if score > best_score { best_node, best_score = candidate, score }
		}
		if best_node < 0 { return -1 }
		selected |= u16(1) << best_node
		chosen[round], scores[round] = i64(best_node), best_score
	}
	bytes := 8 * (1 + 2*k)
	if output == nil || capacity < usize(bytes) { return -2 }
	put_i64_le(mut output, 0, i64(k))
	for round in 0 .. k {
		put_i64_le(mut output, 1 + 2*round, chosen[round])
		put_i64_le(mut output, 2 + 2*round, scores[round])
	}
	return i64(bytes)
}
