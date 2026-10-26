package frt_tree_metric

import "core:c"

within :: proc(d, beta: i64, level: int) -> bool {
	if level >= 0 do return d*1024 <= beta*(i64(1)<<level)
	return d*1024*(i64(1)<<(-level)) <= beta
}
put_i64 :: proc(out: [^]u8, offset: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[offset+b] = u8((bits >> u64(8*b)) & 255) }
}

frt_tree_metric :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 8 || length > 74 do return -1
	n0, beta := input[0], input[1]
	if n0 < 2 || n0 > 8 || beta < 1024 || beta > 2047 do return -1
	n := int(n0)
	if length != c.size_t(2+n+n*n) do return -1
	perm: [8]int; seen: [8]bool
	for i := 0; i < n; i += 1 {
		p := input[2+i]
		if p < 0 || p >= n0 || seen[int(p)] do return -1
		seen[int(p)] = true; perm[i] = int(p)
	}
	d: [8][8]i64; maxd: i64 = 0; base := 2+n
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 {
		x := input[base+i*n+j]
		if x < 0 || x > 255 || (i == j && x != 0) || (i != j && x == 0) do return -1
		d[i][j] = x; if x > maxd do maxd = x
	} }
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 {
		if d[i][j] != d[j][i] do return -1
		for k := 0; k < n; k += 1 { if d[i][j] > d[i][k]+d[k][j] do return -1 }
	} }
	high := 0; for (i64(1)<<high) < maxd { high += 1 }
	staged: [64]i64; clusters: [256]u16; next: [256]u16
	count := 1; clusters[0] = u16((1<<n)-1)
	for level := high; level >= -10; level -= 1 {
		next_count := 0; td := i64(1) << (level+13)
		for ci := 0; ci < count; ci += 1 {
			remaining := clusters[ci]; done: u16 = 0
			for remaining != 0 {
				center := n
				for p := 0; p < n; p += 1 { if (remaining & (u16(1)<<perm[p])) != 0 { center = perm[p]; break } }
				if center == n do return -1
				child: u16 = 0
				for v := 0; v < n; v += 1 { if (remaining & (u16(1)<<v)) != 0 && within(d[center][v], beta, level) { child |= u16(1)<<v } }
				if child == 0 do child = u16(1)<<center
				for u := 0; u < n; u += 1 { if (done & (u16(1)<<u)) != 0 { for v := 0; v < n; v += 1 { if (child & (u16(1)<<v)) != 0 { staged[u*n+v] = td; staged[v*n+u] = td } } } }
				done |= child; remaining &= ~child; next[next_count] = child; next_count += 1
			}
		}
		for i := 0; i < next_count; i += 1 { clusters[i] = next[i] }; count = next_count
	}
	bytes := 8*n*n
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < n*n; i += 1 { put_i64(output, i*8, staged[i]) }
	return i64(bytes)
}
