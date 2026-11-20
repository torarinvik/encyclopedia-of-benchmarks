package deterministic_linear_threshold_spread

import "core:c"

store_i64_le :: proc(output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (byte * 8))
	}
}

@(export)
deterministic_linear_threshold_spread :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 92 do return -1
	n_raw, m_raw, s_raw := input[0], input[1], input[2]
	if n_raw < 1 || n_raw > 8 || m_raw < 0 || m_raw > 24 || s_raw < 0 || s_raw > n_raw do return -1
	n, m, seed_count := c.size_t(n_raw), c.size_t(m_raw), c.size_t(s_raw)
	edge_offset := 3 + seed_count
	threshold_offset := edge_offset + 3 * m
	if length != threshold_offset + n do return -1
	seeded: [8]bool
	seen: [64]bool
	head: [8]i64
	edge_to, edge_weight, edge_next: [24]i64
	incoming, threshold, activation_round, accumulated: [8]i64
	for v := c.size_t(0); v < n; v += 1 { head[v] = -1; activation_round[v] = -1 }
	for i := c.size_t(0); i < seed_count; i += 1 {
		seed := input[3 + i]
		if seed < 0 || u64(seed) >= u64(n) || seeded[c.size_t(seed)] do return -1
		seeded[c.size_t(seed)] = true
		activation_round[c.size_t(seed)] = 0
	}
	for i := c.size_t(0); i < m; i += 1 {
		u, v, w := input[edge_offset + 3 * i], input[edge_offset + 3 * i + 1], input[edge_offset + 3 * i + 2]
		if u < 0 || u64(u) >= u64(n) || v < 0 || u64(v) >= u64(n) || u == v || w < 0 || w > 16 do return -1
		slot := c.size_t(u) * 8 + c.size_t(v)
		if seen[slot] do return -1
		seen[slot] = true
		incoming[c.size_t(v)] += w
		if incoming[c.size_t(v)] > 16 do return -1
		edge_to[i] = v
		edge_weight[i] = w
		edge_next[i] = head[c.size_t(u)]
		head[c.size_t(u)] = i64(i)
	}
	for v := c.size_t(0); v < n; v += 1 {
		threshold[v] = input[threshold_offset + v]
		if threshold[v] < 1 || threshold[v] > 16 do return -1
	}
	output_bytes := 8 * (n + 2)
	if output == nil || capacity < output_bytes do return -2
	current, next: [8]c.size_t
	current_count, waves := c.size_t(0), i64(0)
	for v := c.size_t(0); v < n; v += 1 { if seeded[v] { current[current_count] = v; current_count += 1 } }
	for current_count > 0 {
		next_count := c.size_t(0)
		for i := c.size_t(0); i < current_count; i += 1 {
			source := current[i]
			for edge := head[source]; edge >= 0; edge = edge_next[c.size_t(edge)] {
				target := c.size_t(edge_to[c.size_t(edge)])
				if activation_round[target] >= 0 do continue
				accumulated[target] += edge_weight[c.size_t(edge)]
				if accumulated[target] >= threshold[target] {
					activation_round[target] = waves + 1
					next[next_count] = target
					next_count += 1
				}
			}
		}
		current_count = next_count
		for i := c.size_t(0); i < next_count; i += 1 { current[i] = next[i] }
		if next_count > 0 do waves += 1
	}
	store_i64_le(output, 0, n_raw); store_i64_le(output, 8, waves)
	for v := c.size_t(0); v < n; v += 1 { store_i64_le(output, 8 * (v + 2), activation_round[v]) }
	return i64(output_bytes)
}
