package is_graph_bipartite

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 256
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGES

@(export)
is_graph_bipartite :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	vertex_count_raw := values[0]
	edge_count_raw := values[1]
	if vertex_count_raw < 0 || vertex_count_raw > MAX_VERTICES ||
		edge_count_raw < 0 || edge_count_raw > MAX_EDGES do return -1
	vertex_count := int(vertex_count_raw)
	edge_count := int(edge_count_raw)
	if length != 2 + 2 * edge_count do return -1

	head: [MAX_VERTICES]int
	arc_to: [2 * MAX_EDGES]int
	arc_next: [2 * MAX_EDGES]int
	side: [MAX_VERTICES]int
	queue: [MAX_VERTICES]int
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		head[vertex] = -1
		side[vertex] = -1
	}
	arc_count := 0
	for edge := 0; edge < edge_count; edge += 1 {
		u_raw := values[2 + 2 * edge]
		v_raw := values[3 + 2 * edge]
		if u_raw < 1 || u_raw > vertex_count_raw || v_raw < 1 || v_raw > vertex_count_raw do return -1
		u := int(u_raw - 1)
		v := int(v_raw - 1)
		arc_to[arc_count] = v
		arc_next[arc_count] = head[u]
		head[u] = arc_count
		arc_count += 1
		arc_to[arc_count] = u
		arc_next[arc_count] = head[v]
		head[v] = arc_count
		arc_count += 1
	}

	bipartite := true
	for start := 0; start < vertex_count; start += 1 {
		if side[start] != -1 do continue
		queue_head := 0
		queue_tail := 1
		queue[0] = start
		side[start] = 0
		for queue_head < queue_tail {
			current := queue[queue_head]
			queue_head += 1
			for arc := head[current]; arc != -1; arc = arc_next[arc] {
				neighbor := arc_to[arc]
				if side[neighbor] == -1 {
					side[neighbor] = side[current] ^ 1
					queue[queue_tail] = neighbor
					queue_tail += 1
				} else if side[neighbor] == side[current] {
					bipartite = false
				}
			}
		}
	}
	if bipartite do return 1
	return 0
}
