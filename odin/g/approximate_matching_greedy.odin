package approximate_matching_greedy

import "core:c"

Edge :: struct { u, v: int, weight: i64, used: bool }

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

approximate_matching_greedy :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 98 do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > 12 || m0 < 0 || m0 > 32 || length != c.size_t(2+3*m0) do return -1
	m := int(m0)
	seen: [12][12]bool; matched: [12]bool; edges: [32]Edge
	for i := 0; i < m; i += 1 {
		u0, v0, weight := input[2+3*i], input[3+3*i], input[4+3*i]
		if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || weight < 1 || weight > 100 do return -1
		u, v := int(u0), int(v0)
		lo, hi := u, v; if lo > hi { lo, hi = hi, lo }
		if seen[lo][hi] do return -1
		seen[lo][hi] = true; edges[i] = Edge{u, v, weight, false}
	}
	if output == nil || capacity < 16 do return -2
	total := i64(0); selected := u64(0)
	for step := 0; step < m; step += 1 {
		best := m
		for i := 0; i < m; i += 1 { if !edges[i].used && (best == m || edges[i].weight > edges[best].weight) { best = i } }
		edges[best].used = true; edge := edges[best]
		if !matched[edge.u] && !matched[edge.v] {
			matched[edge.u] = true; matched[edge.v] = true
			selected |= u64(1) << u32(best); total += edge.weight
		}
	}
	put_i64(output, 0, total); put_i64(output, 1, cast(i64)selected)
	return 16
}
