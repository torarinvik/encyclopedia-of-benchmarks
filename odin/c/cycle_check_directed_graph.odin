package cycle_check_directed_graph

import "core:c"

// Directed cycle detection with iterative depth-first search and three colors.
@(export)
cycle_check_directed_graph :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 65 || (length - 1) % 2 != 0 do return -1
	if values[0] < 0 || values[0] > 64 do return -1
	vertices := c.size_t(values[0])
	edge_count := (length - 1) / 2
	if edge_count > 32 do return -1
	adjacency: [64]u64
	state: [64]u8
	stack: [64]c.size_t
	next_neighbor: [64]c.size_t
	for vertex: c.size_t = 0; vertex < 64; vertex += 1 {
		adjacency[vertex] = 0
		state[vertex] = 0
	}
	for edge: c.size_t = 0; edge < edge_count; edge += 1 {
		source_value := values[1 + 2 * edge]
		destination_value := values[2 + 2 * edge]
		if source_value < 0 || destination_value < 0 ||
			u64(source_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
			return -1
		}
		source := c.size_t(source_value)
		destination := c.size_t(destination_value)
		adjacency[source] |= u64(1) << destination
	}
	for root: c.size_t = 0; root < vertices; root += 1 {
		if state[root] != 0 do continue
		top := c.size_t(0)
		stack[top] = root
		next_neighbor[top] = 0
		state[root] = 1
		for {
			node := stack[top]
			destination := next_neighbor[top]
			for destination < vertices &&
				(adjacency[node] & (u64(1) << destination)) == 0 {
				destination += 1
			}
			if destination == vertices {
				state[node] = 2
				if top == 0 do break
				top -= 1
				continue
			}
			next_neighbor[top] = destination + 1
			if state[destination] == 1 do return 1
			if state[destination] == 0 {
				top += 1
				stack[top] = destination
				next_neighbor[top] = 0
				state[destination] = 1
			}
		}
	}
	return 0
}
