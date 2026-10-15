package cycle_check_directed_graph_kahn

import "core:c"

// Directed cycle detection with Kahn's zero-indegree queue.
@(export)
cycle_check_directed_graph_kahn :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 65 || (length - 1) % 2 != 0 do return -1
	if values[0] < 0 || values[0] > 64 do return -1
	vertices := c.size_t(values[0])
	edge_count := (length - 1) / 2
	if edge_count > 32 do return -1
	adjacency: [64]u64
	indegree: [64]c.size_t
	for vertex: c.size_t = 0; vertex < 64; vertex += 1 {
		adjacency[vertex] = 0
		indegree[vertex] = 0
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
		mask := u64(1) << destination
		if (adjacency[source] & mask) == 0 {
			adjacency[source] |= mask
			indegree[destination] += 1
		}
	}
	queue: [64]c.size_t
	head := c.size_t(0)
	tail := c.size_t(0)
	for vertex: c.size_t = 0; vertex < vertices; vertex += 1 {
		if indegree[vertex] == 0 {
			queue[tail] = vertex
			tail += 1
		}
	}
	removed := c.size_t(0)
	for head < tail {
		source := queue[head]
		head += 1
		removed += 1
		for destination: c.size_t = 0; destination < vertices; destination += 1 {
			if (adjacency[source] & (u64(1) << destination)) != 0 {
				indegree[destination] -= 1
				if indegree[destination] == 0 {
					queue[tail] = destination
					tail += 1
				}
			}
		}
	}
	if removed != vertices do return 1
	return 0
}
