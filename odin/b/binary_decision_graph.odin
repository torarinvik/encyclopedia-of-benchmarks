package binary_decision_graph

import "core:c"

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[at*8+b] = u8((bits >> u64(8*b)) & 255) }
}

binary_decision_graph :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 65 do return -1
	nv := input[0]
	if nv < 1 || nv > 6 || length != 1 + (c.size_t(1) << u(nv)) do return -1
	n := int(nv)
	count := 1 << n
	ids: [64]i64
	next: [64]i64
	vars: [63]i64
	lows: [63]i64
	highs: [63]i64
	for i := 0; i < count; i += 1 {
		if input[i+1] != 0 && input[i+1] != 1 do return -1
		ids[i] = input[i+1]
	}
	nodes := 0
	current_count := count
	for step := 0; step < n; step += 1 {
		variable := n - 1 - step
		next_count := current_count / 2
		for p := 0; p < next_count; p += 1 {
			lo, hi := ids[2*p], ids[2*p+1]
			if lo == hi { next[p] = lo; continue }
			found := nodes
			j := nodes
			for j > 0 {
				j -= 1
				if int(vars[j]) != variable do break
				if lows[j] == lo && highs[j] == hi { found = j; break }
			}
			if found == nodes {
				vars[nodes] = i64(variable); lows[nodes] = lo; highs[nodes] = hi
				next[p] = i64(2 + nodes); nodes += 1
			} else { next[p] = i64(2 + found) }
		}
		for p := 0; p < next_count; p += 1 { ids[p] = next[p] }
		current_count = next_count
	}
	bytes := 8 * (2 + 3 * nodes)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, ids[0]); put_i64(output, 1, i64(nodes))
	for i := 0; i < nodes; i += 1 {
		put_i64(output, 2+3*i, vars[i]); put_i64(output, 3+3*i, lows[i]); put_i64(output, 4+3*i, highs[i])
	}
	return i64(bytes)
}
