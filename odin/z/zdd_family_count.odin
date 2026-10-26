package zdd_family_count

import "core:c"

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[at*8+b] = u8((bits >> u64(8*b)) & 255) }
}

zdd_family_count :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 34 do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > 6 || m0 < 0 || m0 > 32 || length != c.size_t(m0+2) do return -1
	n, m := int(n0), int(m0)
	limit := 1 << n
	ids: [64]i64; next: [64]i64
	vars: [63]i64; lows: [63]i64; highs: [63]i64
	counts: [65]i64; seen: [64]bool
	counts[1] = 1
	for i := 0; i < m; i += 1 {
		mask := input[2+i]
		if mask < 0 || mask >= i64(limit) || seen[int(mask)] do return -1
		seen[int(mask)] = true; ids[int(mask)] = 1
	}
	nodes, current_count := 0, limit
	for variable := 0; variable < n; variable += 1 {
		next_count := current_count / 2
		for p := 0; p < next_count; p += 1 {
			low, high := ids[2*p], ids[2*p+1]
			if high == 0 { next[p] = low; continue }
			found, j := nodes, nodes
			for j > 0 {
				j -= 1
				if int(vars[j]) != variable do break
				if lows[j] == low && highs[j] == high { found = j; break }
			}
			if found == nodes {
				vars[nodes] = i64(variable); lows[nodes] = low; highs[nodes] = high
				counts[2+nodes] = counts[int(low)] + counts[int(high)]
				next[p] = i64(2+nodes); nodes += 1
			} else { next[p] = i64(2+found) }
		}
		for p := 0; p < next_count; p += 1 { ids[p] = next[p] }
		current_count = next_count
	}
	bytes := 8 * (3 + 3 * nodes)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, ids[0]); put_i64(output, 1, i64(nodes)); put_i64(output, 2, counts[int(ids[0])])
	for i := 0; i < nodes; i += 1 {
		put_i64(output, 3+3*i, vars[i]); put_i64(output, 4+3*i, lows[i]); put_i64(output, 5+3*i, highs[i])
	}
	return i64(bytes)
}
