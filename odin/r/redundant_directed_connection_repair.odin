package redundant_directed_connection_repair

import "core:c"

MAX_N :: 16

repair_find :: proc(parent: [^]int, node_input: int) -> int {
	node := node_input
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

@(export)
redundant_directed_connection_repair :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 34 do return -1
	n_value := input[0]
	if n_value < 3 || n_value > MAX_N do return -1
	n := int(n_value)
	if int(length) != 1+2*n do return -1
	from: [MAX_N]int
	to: [MAX_N]int
	incoming: [MAX_N]int
	parent: [MAX_N]int
	sizes: [MAX_N]int
	for node := 0; node < n; node += 1 { incoming[node] = -1; parent[node] = node; sizes[node] = 1 }
	for edge := 0; edge < n; edge += 1 {
		u, v := input[1+2*edge], input[2+2*edge]
		if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v do return -1
		from[edge], to[edge] = int(u), int(v)
		for prior := 0; prior < edge; prior += 1 {
			if from[prior] == from[edge] && to[prior] == to[edge] do return -1
		}
	}
	first_parent, second_parent := -1, -1
	for edge := 0; edge < n; edge += 1 {
		child := to[edge]
		if incoming[child] < 0 do incoming[child] = edge
		else { first_parent = incoming[child]; second_parent = edge; break }
	}
	cycle_edge := -1
	for edge := 0; edge < n; edge += 1 {
		if edge == second_parent do continue
		a := repair_find(&parent[0], from[edge])
		b := repair_find(&parent[0], to[edge])
		if a == b { cycle_edge = edge; break }
		if sizes[a] < sizes[b] { a, b = b, a }
		parent[b] = a
		sizes[a] += sizes[b]
	}
	if cycle_edge >= 0 {
		if second_parent >= 0 do return i64(first_parent)
		return i64(cycle_edge)
	}
	return i64(second_parent)
}
