package even_tree

import "core:c"

@(export)
even_tree :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	invalid := i64(-9223372036854775807) - 1
	if values == nil || length < 2 do return invalid
	n_value, edge_value := values[0], values[1]
	if n_value < 2 || n_value > 100 || n_value % 2 != 0 || edge_value != n_value - 1 do return invalid
	n, edge_count := int(n_value), int(edge_value)
	if length != c.size_t(2 + 2 * edge_count) do return invalid
	adjacency: [100][100]bool
	for i := 0; i < edge_count; i += 1 {
		u_value, v_value := values[2 + 2 * i], values[3 + 2 * i]
		if u_value < 1 || u_value > n_value || v_value < 1 || v_value > n_value || u_value == v_value do return invalid
		u, v := int(u_value - 1), int(v_value - 1)
		if adjacency[u][v] do return invalid
		adjacency[u][v] = true
		adjacency[v][u] = true
	}
	parents: [100]int
	stack: [100]int
	order: [100]int
	subtree: [100]i64
	for i := 0; i < n; i += 1 {
		parents[i] = -2
		subtree[i] = 1
	}
	parents[0] = -1
	top, order_count := 0, 0
	stack[top] = 0
	top += 1
	for top > 0 {
		top -= 1
		u := stack[top]
		order[order_count] = u
		order_count += 1
		for v := 0; v < n; v += 1 {
			if adjacency[u][v] && parents[v] == -2 {
				parents[v] = u
				stack[top] = v
				top += 1
			}
		}
	}
	if order_count != n do return invalid
	cuts: i64 = 0
	index := order_count
	for index > 0 {
		index -= 1
		u := order[index]
		if parents[u] >= 0 do subtree[parents[u]] += subtree[u]
		if subtree[u] % 2 == 0 do cuts += 1
	}
	return cuts - 1
}
