module deterministic_linear_threshold_spread

fn dlt_store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'deterministic_linear_threshold_spread']
pub fn deterministic_linear_threshold_spread(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 92 { return -1 }
	unsafe {
		n_raw, m_raw, s_raw := input[0], input[1], input[2]
		if n_raw < 1 || n_raw > 8 || m_raw < 0 || m_raw > 24 || s_raw < 0 || s_raw > n_raw { return -1 }
		n, m, seed_count := int(n_raw), int(m_raw), int(s_raw)
		edge_offset := 3 + seed_count
		threshold_offset := edge_offset + 3 * m
		if int(length) != threshold_offset + n { return -1 }
		mut seeded := [8]bool{}
		mut seen := [64]bool{}
		mut head := [8]i64{init: -1}
		mut edge_to := [24]i64{}
		mut edge_weight := [24]i64{}
		mut edge_next := [24]i64{init: -1}
		mut incoming := [8]i64{}
		mut threshold := [8]i64{}
		mut activation_round := [8]i64{init: -1}
		mut accumulated := [8]i64{}
		for i in 0 .. seed_count {
			seed := input[3 + i]
			if seed < 0 || seed >= n_raw || seeded[int(seed)] { return -1 }
			seeded[int(seed)] = true
			activation_round[int(seed)] = 0
		}
		for i in 0 .. m {
			u := input[edge_offset + 3 * i]
			v := input[edge_offset + 3 * i + 1]
			w := input[edge_offset + 3 * i + 2]
			if u < 0 || u >= n_raw || v < 0 || v >= n_raw || u == v || w < 0 || w > 16 { return -1 }
			slot := int(u) * 8 + int(v)
			if seen[slot] { return -1 }
			seen[slot] = true
			incoming[int(v)] += w
			if incoming[int(v)] > 16 { return -1 }
			edge_to[i] = v
			edge_weight[i] = w
			edge_next[i] = head[int(u)]
			head[int(u)] = i64(i)
		}
		for v in 0 .. n {
			threshold[v] = input[threshold_offset + v]
			if threshold[v] < 1 || threshold[v] > 16 { return -1 }
		}
		output_bytes := 8 * (n + 2)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut frontier := [8]int{}
		mut following := [8]int{}
		mut frontier_count := 0
		for v in 0 .. n { if seeded[v] { frontier[frontier_count] = v; frontier_count++ } }
		mut waves := i64(0)
		for frontier_count > 0 {
			mut following_count := 0
			for i in 0 .. frontier_count {
				source := frontier[i]
				mut edge := head[source]
				for edge >= 0 {
					target := int(edge_to[int(edge)])
					if activation_round[target] < 0 {
						accumulated[target] += edge_weight[int(edge)]
						if accumulated[target] >= threshold[target] {
							activation_round[target] = waves + 1
							following[following_count] = target
							following_count++
						}
					}
					edge = edge_next[int(edge)]
				}
			}
			frontier_count = following_count
			for i in 0 .. following_count { frontier[i] = following[i] }
			if following_count > 0 { waves++ }
		}
		dlt_store_i64(mut output, 0, n_raw)
		dlt_store_i64(mut output, 8, waves)
		for v in 0 .. n { dlt_store_i64(mut output, 8 * (v + 2), activation_round[v]) }
		return i64(output_bytes)
	}
}
