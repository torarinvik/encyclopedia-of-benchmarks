package approximating_diameter_bfs

import "core:c"

put_i64 :: proc(out: [^]u8, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[b] = u8((bits >> u64(8*b)) & 255) }
}

approximating_diameter_bfs :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 242 do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > 16 || m0 < 0 || m0 > 120 || length != c.size_t(2+2*m0) do return -1
	n, m := int(n0), int(m0)
	adj: [16][16]bool
	for i := 0; i < m; i += 1 {
		u0, v0 := input[2+2*i], input[3+2*i]
		if u0 < 0 || v0 <= u0 || v0 >= n0 do return -1
		u, v := int(u0), int(v0)
		if adj[u][v] do return -1
		adj[u][v] = true; adj[v][u] = true
	}
	dist: [16]i64; queue: [16]int
	for i := 0; i < n; i += 1 { dist[i] = -1 }
	dist[0] = 0; queue[0] = 0; head, tail := 0, 1
	for head < tail {
		u := queue[head]; head += 1
		for v := 0; v < n; v += 1 {
			if adj[u][v] && dist[v] < 0 { dist[v] = dist[u] + 1; queue[tail] = v; tail += 1 }
		}
	}
	if tail != n do return -1
	estimate := i64(0)
	for i := 0; i < n; i += 1 { if dist[i] > estimate do estimate = dist[i] }
	if output == nil || capacity < 8 do return -2
	put_i64(output, estimate)
	return 8
}
