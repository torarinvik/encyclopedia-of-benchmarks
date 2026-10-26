package thorup_zwick_distance_oracle

import "core:c"

N :: 12
M :: 66
Q :: 32
INF :: i64(0x3fffffffffffffff)

@(export)
thorup_zwick_distance_oracle :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 266 do return -1
	n64, m64, mask := input[0], input[1], input[2]
	if n64 < 1 || n64 > N || m64 < 0 || m64 > M || mask <= 0 do return -1
	n, m := int(n64), int(m64)
	if (u64(mask) >> n) != 0 do return -1
	q_at := 3 + 3*m
	if q_at >= int(length) || input[q_at] < 0 || input[q_at] > Q do return -1
	q := int(input[q_at])
	if int(length) != q_at + 1 + 2*q do return -1
	var d: [N][N]i64
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { d[i][j] = if i == j { 0 } else { INF } } }
	for e := 0; e < m; e += 1 {
		u64, v64, w := input[3+3*e], input[4+3*e], input[5+3*e]
		if u64 < 0 || v64 <= u64 || v64 >= n64 || w < 1 || w > 1000 do return -1
		u, v := int(u64), int(v64)
		if d[u][v] != INF do return -1
		d[u][v], d[v][u] = w, w
	}
	for k := 0; k < n; k += 1 { for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 {
		if d[i][k] != INF && d[k][j] != INF && d[i][k]+d[k][j] < d[i][j] { d[i][j] = d[i][k]+d[k][j] }
	} } }
	for i := 0; i < n; i += 1 { for j := 0; j < n; j += 1 { if d[i][j] == INF do return -1 } }
	var nearest: [N]int
	var near_d: [N]i64
	for v := 0; v < n; v += 1 {
		nearest[v], near_d[v] = -1, INF
		for a := 0; a < n; a += 1 { if ((u64(mask) >> a) & 1) != 0 {
			if d[v][a] < near_d[v] || (d[v][a] == near_d[v] && (nearest[v] < 0 || a < nearest[v])) { nearest[v], near_d[v] = a, d[v][a] }
		} }
	}
	var bunch: [N][N]bool
	for u := 0; u < n; u += 1 { for x := 0; x < n; x += 1 { bunch[u][x] = ((u64(mask) >> x) & 1) != 0 || d[u][x] < near_d[u] } }
	var staged: [Q+1]i64
	staged[0] = i64(q)
	for z := 0; z < q; z += 1 {
		a, b := input[q_at+1+2*z], input[q_at+2+2*z]
		if a < 0 || a >= n64 || b < 0 || b >= n64 do return -1
		u, v := int(a), int(b)
		found := false
		for level := 0; level < 2; level += 1 {
			pivot := if level == 0 { v } else { nearest[v] }
			if bunch[u][pivot] { staged[z+1] = d[u][pivot]+d[v][pivot]; found = true; break }
			u, v = v, u
		}
		if !found do return -1
	}
	bytes := 8*(q+1)
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < q+1; i += 1 {
		bits := u64(staged[i])
		for b := 0; b < 8; b += 1 { output[i*8+b] = u8(bits >> (8*b)) }
	}
	return i64(bytes)
}
