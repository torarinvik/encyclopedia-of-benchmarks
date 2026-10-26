package metric_tsp_tree_doubling

import "core:c"

MAX_N :: 8
MAX_INPUT :: 65

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[offset+b] = u8(bits & 255); bits >>= 8 }
}

@(export)
metric_tsp_tree_doubling :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 1 || n64 > MAX_N || length != c.size_t(1+n64*n64) do return -1
	n := int(n64)
	d: [MAX_N][MAX_N]i64
	for u := 0; u < n; u += 1 {
		for v := 0; v < n; v += 1 {
			w := input[1+u*n+v]
			if w < 0 || w > 10000 || (u == v && w != 0) do return -1
			d[u][v] = w
		}
	}
	for u := 0; u < n; u += 1 { for v := u+1; v < n; v += 1 do if d[u][v] != d[v][u] do return -1 }
	for u := 0; u < n; u += 1 { for v := 0; v < n; v += 1 { for k := 0; k < n; k += 1 do if d[u][v] > d[u][k]+d[k][v] do return -1 } }
	output_bytes := 8*(n+2)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	processed: [MAX_N][MAX_N]bool
	tree: [MAX_N][MAX_N]bool
	parent: [MAX_N]int
	for i := 0; i < n; i += 1 { parent[i] = i }
	accepted := 0
	edge_count := n*(n-1)/2
	for step := 0; step < edge_count && accepted+1 < n; step += 1 {
		bu, bv, bw := 0, 0, i64(9223372036854775807)
		for u := 0; u < n; u += 1 { for v := u+1; v < n; v += 1 { if !processed[u][v] && d[u][v] < bw { bu, bv, bw = u, v, d[u][v] } } }
		processed[bu][bv] = true
		ru, rv := bu, bv
		for parent[ru] != ru { ru = parent[ru] }
		for parent[rv] != rv { rv = parent[rv] }
		if ru != rv { parent[rv] = ru; tree[bu][bv] = true; tree[bv][bu] = true; accepted += 1 }
	}
	stack: [MAX_N]int
	order: [MAX_N]int
	visited: [MAX_N]bool
	top, count := 1, 0
	stack[0] = 0
	for top > 0 {
		top -= 1
		v := stack[top]
		if visited[v] do continue
		visited[v] = true
		order[count] = v
		count += 1
		for rev := n-1; rev >= 0; rev -= 1 { if tree[v][rev] && !visited[rev] { stack[top] = rev; top += 1 } }
	}
	cost: i64 = 0
	for i := 0; i+1 < n; i += 1 { cost += d[order[i]][order[i+1]] }
	cost += d[order[n-1]][0]
	store_i64_le(output, 0, cost)
	for i := 0; i < n; i += 1 do store_i64_le(output, 8*(i+1), i64(order[i]))
	store_i64_le(output, 8*(n+1), 0)
	return i64(output_bytes)
}
