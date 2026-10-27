package weighted_greedy_spanner

import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 88
INF :: i64(1) << 60

@(export)
weighted_greedy_spanner :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n64, m64, k := input[0], input[1], input[2]
	if n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || k < 1 || k > 3 ||
		length != c.size_t(3 + 3*m64) do return -1
	n, m := int(n64), int(m64)
	var edge_u, edge_v, edge_w: [MAX_M]i64
	var order: [MAX_M]int
	var selected: [MAX_M]u8
	var adjacency: [MAX_N * MAX_N]i64
	for i := 0; i < m; i += 1 {
		edge_u[i] = input[3+3*i]
		edge_v[i] = input[4+3*i]
		edge_w[i] = input[5+3*i]
		if edge_u[i] < 0 || edge_v[i] <= edge_u[i] || edge_v[i] >= n64 || edge_w[i] < 1 || edge_w[i] > 32 do return -1
		for j := 0; j < i; j += 1 do if edge_u[j] == edge_u[i] && edge_v[j] == edge_v[i] do return -1
		order[i] = i
	}
	for i := 1; i < m; i += 1 {
		key := order[i]
		pos := i
		for pos > 0 {
			prev := order[pos-1]
			if edge_w[prev] < edge_w[key] || (edge_w[prev] == edge_w[key] && edge_u[prev] < edge_u[key]) ||
				(edge_w[prev] == edge_w[key] && edge_u[prev] == edge_u[key] && edge_v[prev] <= edge_v[key]) do break
			order[pos] = prev
			pos -= 1
		}
		order[pos] = key
	}
	if output == nil || capacity < c.size_t(m) do return -2
	for rank := 0; rank < m; rank += 1 {
		edge := order[rank]
		source, target := int(edge_u[edge]), int(edge_v[edge])
		var distance: [MAX_N]i64
		var settled: [MAX_N]bool
		for v := 0; v < n; v += 1 do distance[v] = INF
		distance[source] = 0
		for _ in 0..<n {
			vertex := n
			for v := 0; v < n; v += 1 do if !settled[v] && (vertex == n || distance[v] < distance[vertex]) do vertex = v
			if vertex == n || distance[vertex] == INF do break
			settled[vertex] = true
			for v := 0; v < n; v += 1 {
				weight := adjacency[vertex*MAX_N+v]
				if weight > 0 && distance[v] > distance[vertex]+weight do distance[v] = distance[vertex]+weight
			}
		}
		if distance[target] > (2*k-1)*edge_w[edge] {
			selected[edge] = 1
			adjacency[source*MAX_N+target] = edge_w[edge]
			adjacency[target*MAX_N+source] = edge_w[edge]
		}
	}
	for i := 0; i < m; i += 1 do output[i] = selected[i]
	return i64(m)
}
