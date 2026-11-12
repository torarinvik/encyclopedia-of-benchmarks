package tree_edge_paint_path_count

import "core:c"

MAX_N :: 16
MAX_Q :: 32
MAX_EDGES :: 15
LOG_N :: 5

root_of :: proc(parent: ^[MAX_N]int, node_arg: int) -> int {
	node := node_arg
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

point_set :: proc(tree: ^[64]i64, base, index: int, value: i64) {
	position := base + index
	tree[position] = value
	position /= 2
	for position > 0 {
		tree[position] = tree[2 * position] + tree[2 * position + 1]
		position /= 2
	}
}

range_sum :: proc(tree: ^[64]i64, base, left, right: int) -> i64 {
	if left > right do return 0
	l, r := base + left, base + right + 1
	total := i64(0)
	for l < r {
		if l & 1 == 1 { total += tree[l]; l += 1 }
		if r & 1 == 1 { r -= 1; total += tree[r] }
		l /= 2
		r /= 2
	}
	return total
}

lca :: proc(a_arg, b_arg: int, depth, parent: ^[MAX_N]int, ancestor: ^[LOG_N * MAX_N]int) -> int {
	a, b := a_arg, b_arg
	if depth[a] < depth[b] { a, b = b, a }
	difference := depth[a] - depth[b]
	for bit := 0; bit < LOG_N; bit += 1 {
		if ((difference >> bit) & 1) != 0 do a = ancestor[bit * MAX_N + a]
	}
	if a == b do return a
	for bit := LOG_N - 1; bit >= 0; bit -= 1 {
		if ancestor[bit * MAX_N + a] != ancestor[bit * MAX_N + b] {
			a = ancestor[bit * MAX_N + a]
			b = ancestor[bit * MAX_N + b]
		}
	}
	return parent[a]
}

@(export)
tree_edge_paint_path_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 129 do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q do return -1
	n, q := int(input[0]), int(input[1])
	m := n - 1
	if length != c.size_t(2 + 2*m + 3*q) do return -1

	edge_u := [MAX_EDGES]int{}
	edge_v := [MAX_EDGES]int{}
	dsu := [MAX_N]int{}
	for i := 0; i < n; i += 1 do dsu[i] = i
	cursor := c.size_t(2)
	for edge := 0; edge < m; edge += 1 {
	u_value, v_value := input[cursor], input[cursor + 1]; cursor += 2
	if u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value do return -1
	u, v := int(u_value), int(v_value)
	edge_u[edge], edge_v[edge] = u, v
	ru := root_of(&dsu, u); rv := root_of(&dsu, v)
	if ru == rv do return -1
	dsu[ru] = rv
	}
	root := root_of(&dsu, 0)
	for v := 1; v < n; v += 1 do if root_of(&dsu, v) != root do return -1

	parent := [MAX_N]int{}
	depth := [MAX_N]int{}
	first := [MAX_N]int{}
	visited := [MAX_N]bool{}
	down := [MAX_EDGES]int{}
	up := [MAX_EDGES]int{}
	stack_node := [MAX_N]int{}
	stack_parent := [MAX_N]int{}
	stack_in := [MAX_N]int{}
	stack_cursor := [MAX_N]int{}
	stack_parent[0], stack_in[0], visited[0] = -1, -1, true
	top, occurrences := 0, 0
	for top >= 0 {
	node, found := stack_node[top], false
	for stack_cursor[top] < m {
	edge := stack_cursor[top]; stack_cursor[top] += 1
	if edge_u[edge] != node && edge_v[edge] != node do continue
	child := edge_u[edge]; if child == node do child = edge_v[edge]
	if child == stack_parent[top] do continue
	if visited[child] do return -1
	visited[child] = true; parent[child] = node; depth[child] = depth[node] + 1
	down[edge] = occurrences; occurrences += 1; first[child] = occurrences
	top += 1; stack_node[top], stack_parent[top], stack_in[top], stack_cursor[top] = child, node, edge, 0
	found = true; break
	}
	if !found {
	incoming := stack_in[top]; top -= 1
	if incoming >= 0 { up[incoming] = occurrences; occurrences += 1 }
	}
	}

	ancestor := [LOG_N * MAX_N]int{}
	for v := 0; v < n; v += 1 do ancestor[v] = parent[v]
	for k := 1; k < LOG_N; k += 1 {
	for v := 0; v < n; v += 1 do ancestor[k*MAX_N+v] = ancestor[(k-1)*MAX_N+ancestor[(k-1)*MAX_N+v]]
	}
	base := 1; for base < occurrences do base *= 2
	forward := [64]i64{}
	backward := [64]i64{}
	painted := [MAX_EDGES]bool{}
	total := i64(0)
	for operation := 0; operation < q; operation += 1 {
	kind, a, b := input[cursor], input[cursor+1], input[cursor+2]; cursor += 3
	if kind == 0 {
	if a < 0 || a >= m || b != 0 do return -1
	edge := int(a)
	if !painted[edge] {
	painted[edge] = true
	point_set(&forward, base, down[edge], 1)
	point_set(&backward, base, up[edge], 1)
	}
	} else if kind == 1 {
	if a < 0 || a >= n || b < 0 || b >= n do return -1
	common := lca(int(a), int(b), &depth, &parent, &ancestor)
	la, ra := first[common], first[int(a)]-1
	lb, rb := first[common], first[int(b)]-1
	total += range_sum(&forward, base, la, ra)-range_sum(&backward, base, la, ra)
	total += range_sum(&forward, base, lb, rb)-range_sum(&backward, base, lb, rb)
	} else { return -1 }
	}
	return total
}
