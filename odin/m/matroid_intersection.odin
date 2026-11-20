package matroid_intersection

import "core:c"

MAX_VERTICES :: 10
MAX_EDGES :: 20
MAX_COLORS :: 8

mi_is_forest :: proc(input: [^]i64, vertices, edges, edge_start: int,
                     chosen: [MAX_EDGES]bool, removed, added: i64) -> bool {
	parent: [MAX_VERTICES]i64
	for vertex := 0; vertex < vertices; vertex += 1 { parent[vertex] = i64(vertex) }
	for edge := 0; edge < edges; edge += 1 {
		if i64(edge) != added && (!chosen[edge] || i64(edge) == removed) do continue
		a := int(input[edge_start + 3*edge])
		b := int(input[edge_start + 3*edge + 1])
		for parent[a] != i64(a) { a = int(parent[a]) }
		for parent[b] != i64(b) { b = int(parent[b]) }
		if a == b do return false
		parent[b] = i64(a)
	}
	return true
}

mi_within_quotas :: proc(input: [^]i64, colors, edges, edge_start: int,
                         chosen: [MAX_EDGES]bool, removed, added: i64) -> bool {
	counts: [MAX_COLORS]i64
	for edge := 0; edge < edges; edge += 1 {
		if i64(edge) != added && (!chosen[edge] || i64(edge) == removed) do continue
		color := int(input[edge_start + 3*edge + 2])
		counts[color] += 1
		if counts[color] > input[3 + color] do return false
	}
	return true
}

@(export, link_name="matroid_intersection")
matroid_intersection :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 72 do return -1
	vertices_value, edges_value, colors_value := input[0], input[1], input[2]
	if vertices_value < 1 || vertices_value > MAX_VERTICES || edges_value < 0 || edges_value > MAX_EDGES ||
		colors_value < 1 || colors_value > MAX_COLORS do return -1
	vertices, edges, colors := int(vertices_value), int(edges_value), int(colors_value)
	if length != c.size_t(3 + colors + 3*edges) do return -1
	for color := 0; color < colors; color += 1 {
		if input[3 + color] < 0 || input[3 + color] > MAX_EDGES do return -1
	}
	edge_start := 3 + colors
	for edge := 0; edge < edges; edge += 1 {
		u, v, color := input[edge_start + 3*edge], input[edge_start + 3*edge + 1], input[edge_start + 3*edge + 2]
		if u < 0 || u >= vertices_value || v < 0 || v >= vertices_value || color < 0 || color >= colors_value do return -1
	}

	chosen: [MAX_EDGES]bool
	for {
		predecessor: [MAX_EDGES]i64
		for edge := 0; edge < edges; edge += 1 { predecessor[edge] = -2 }
		queue: [MAX_EDGES]i64
		head, tail := 0, 0
		for edge := 0; edge < edges; edge += 1 {
			if !chosen[edge] && mi_is_forest(input, vertices, edges, edge_start, chosen, -1, i64(edge)) {
				predecessor[edge] = -1
				queue[tail] = i64(edge)
				tail += 1
			}
		}
		terminal: i64 = -1
		for head < tail && terminal < 0 {
			current := int(queue[head])
			head += 1
			if !chosen[current] {
				if mi_within_quotas(input, colors, edges, edge_start, chosen, -1, i64(current)) {
					terminal = i64(current)
					break
				}
				for inside := 0; inside < edges; inside += 1 {
					if chosen[inside] && predecessor[inside] == -2 &&
						mi_within_quotas(input, colors, edges, edge_start, chosen, i64(inside), i64(current)) {
						predecessor[inside] = i64(current)
						queue[tail] = i64(inside)
						tail += 1
					}
				}
			} else {
				for outside := 0; outside < edges; outside += 1 {
					if !chosen[outside] && predecessor[outside] == -2 &&
						mi_is_forest(input, vertices, edges, edge_start, chosen, i64(current), i64(outside)) {
						predecessor[outside] = i64(current)
						queue[tail] = i64(outside)
						tail += 1
					}
				}
			}
		}
		if terminal < 0 do break
		node := terminal
		for node >= 0 {
			index := int(node)
			chosen[index] = !chosen[index]
			node = predecessor[index]
		}
	}
	answer: i64 = 0
	for edge := 0; edge < edges; edge += 1 { if chosen[edge] do answer += 1 }
	return answer
}
