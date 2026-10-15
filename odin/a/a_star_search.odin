package a_star_search

import "core:c"

MAX_VERTICES :: 256
MAX_EDGES :: 4096
INF :: i64(2305843009213693951)

@(export)
a_star_search :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > c.size_t(4 + MAX_VERTICES + 2 * MAX_EDGES) do return -1
	vertex_value, edge_value := input[0], input[1]
	source_value, target_value := input[2], input[3]
	if vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES do return -1
	if source_value < 0 || source_value >= vertex_value || target_value < 0 || target_value >= vertex_value do return -1
	vertices, edges := int(vertex_value), int(edge_value)
	source, target := int(source_value), int(target_value)
	if length != c.size_t(4 + vertices + 2 * edges) do return -1

	heuristic: [MAX_VERTICES]i64
	from_vertex: [MAX_EDGES]i64
	to_vertex: [MAX_EDGES]i64
	distance: [MAX_VERTICES]i64
	parent: [MAX_VERTICES]i64
	reversed: [MAX_VERTICES]i64
	opened: [MAX_VERTICES]bool
	closed: [MAX_VERTICES]bool
	for vertex := 0; vertex < vertices; vertex += 1 {
		heuristic[vertex] = input[4 + vertex]
		if heuristic[vertex] < 0 || heuristic[vertex] > 1_000_000_000 do return -1
		distance[vertex] = INF
		parent[vertex] = -1
	}
	if heuristic[target] != 0 do return -1
	edge_offset := 4 + vertices
	for edge := 0; edge < edges; edge += 1 {
		u, v := input[edge_offset + 2 * edge], input[edge_offset + 2 * edge + 1]
		if u < 0 || u >= vertex_value || v < 0 || v >= vertex_value || heuristic[int(u)] > heuristic[int(v)] + 1 do return -1
		from_vertex[edge], to_vertex[edge] = u, v
	}

	distance[source] = 0
	opened[source] = true
	for {
		best := vertices
		for vertex := 0; vertex < vertices; vertex += 1 {
			if !opened[vertex] do continue
			if best == vertices || distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best] ||
				(distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best] &&
				 (distance[vertex] < distance[best] || (distance[vertex] == distance[best] && vertex < best))) {
				best = vertex
			}
		}
		if best == vertices do break
		opened[best] = false
		closed[best] = true
		if best == target do break
		for edge := 0; edge < edges; edge += 1 {
			if int(from_vertex[edge]) != best do continue
			neighbor := int(to_vertex[edge])
			if closed[neighbor] do continue
			candidate := distance[best] + 1
			if candidate < distance[neighbor] {
				distance[neighbor] = candidate
				parent[neighbor] = i64(best)
				opened[neighbor] = true
			}
		}
	}
	if distance[target] == INF do return 0
	path_length := 0
	current := i64(target)
	for current >= 0 && path_length < vertices {
		reversed[path_length] = current
		path_length += 1
		if int(current) == source do break
		current = parent[int(current)]
	}
	if path_length == 0 || int(reversed[path_length - 1]) != source || path_length - 1 > 30 do return -1
	if output_capacity < c.size_t(path_length) || output == nil do return -2
	for index := 0; index < path_length; index += 1 {
		output[index] = u8(reversed[path_length - 1 - index])
	}
	return i64(path_length)
}
