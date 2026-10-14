package bellman_ford

import "core:c"

// Directed edge triples, separate reachability, and checked distance addition.
@(export)
bellman_ford :: proc "c" (edges: [^]i64, vertices, edge_count, source: c.size_t,
						 distances: [^]i64, reachable: [^]u8) -> i64 {
	if vertices == 0 {
		if source == 0 && edge_count == 0 do return 0
		return -3
	}
	if source >= vertices do return -3
	for edge := c.size_t(0); edge < edge_count; edge += 1 {
		origin := edges[3 * edge]
		destination := edges[3 * edge + 1]
		if origin < 0 || destination < 0 || u64(origin) >= u64(vertices) || u64(destination) >= u64(vertices) do return -3
	}
	for vertex := c.size_t(0); vertex < vertices; vertex += 1 {
		distances[vertex] = 0
		reachable[vertex] = 0
	}
	reachable[source] = 1
	for round := c.size_t(0); round < vertices; round += 1 {
		changed := false
		for edge := c.size_t(0); edge < edge_count; edge += 1 {
			origin := c.size_t(edges[3 * edge])
			destination := c.size_t(edges[3 * edge + 1])
			weight := edges[3 * edge + 2]
			if reachable[origin] == 0 do continue
			base := distances[origin]
			if (weight > 0 && base > 9223372036854775807 - weight) ||
			   (weight < 0 && base < (-9223372036854775807 - 1) - weight) {
				return -2
			}
			candidate := base + weight
			if reachable[destination] == 0 || candidate < distances[destination] {
				if round == vertices - 1 do return -1
				distances[destination] = candidate
				reachable[destination] = 1
				changed = true
			}
		}
		if !changed do return 0
	}
	return 0
}
