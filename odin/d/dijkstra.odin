package dijkstra

import "core:c"

// Directed edge triples, nonnegative weights, separate reachability.
@(export)
dijkstra :: proc "c" (edges: [^]i64, vertices, edge_count, source: c.size_t,
                       distances: [^]i64, reachable: [^]u8) -> i64 {
	if vertices == 0 {
		if source == 0 && edge_count == 0 do return 0
		return -3
	}
	if source >= vertices do return -3
	for edge := c.size_t(0); edge < edge_count; edge += 1 {
		origin := edges[3 * edge]
		destination := edges[3 * edge + 1]
		weight := edges[3 * edge + 2]
		if origin < 0 || destination < 0 || u64(origin) >= u64(vertices) || u64(destination) >= u64(vertices) do return -3
		if weight < 0 do return -4
	}
	for vertex := c.size_t(0); vertex < vertices; vertex += 1 {
		distances[vertex] = 0
		reachable[vertex] = 0
	}
	reachable[source] = 1
	for round := c.size_t(0); round < vertices; round += 1 {
		selected := vertices
		best := i64(0)
		for vertex := c.size_t(0); vertex < vertices; vertex += 1 {
			if reachable[vertex] == 1 && (selected == vertices || distances[vertex] < best) {
				selected = vertex
				best = distances[vertex]
			}
		}
		if selected == vertices do break
		reachable[selected] = 2
		for edge := c.size_t(0); edge < edge_count; edge += 1 {
			if c.size_t(edges[3 * edge]) != selected do continue
			destination := c.size_t(edges[3 * edge + 1])
			weight := edges[3 * edge + 2]
			base := distances[selected]
			if base > 9223372036854775807 - weight do return -2
			candidate := base + weight
			if reachable[destination] != 2 && (reachable[destination] == 0 || candidate < distances[destination]) {
				distances[destination] = candidate
				reachable[destination] = 1
			}
		}
	}
	for vertex := c.size_t(0); vertex < vertices; vertex += 1 {
		if reachable[vertex] == 2 do reachable[vertex] = 1
	}
	return 0
}
