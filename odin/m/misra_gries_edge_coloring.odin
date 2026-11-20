package misra_gries_edge_coloring

import "core:c"

MAX_LENGTH :: 15

mg_free :: proc(vertex: int, color: i64, vertices: int,
                edge_at: [36]int, colors: [6]i64) -> bool {
	for other in 0..<vertices {
		edge := edge_at[vertex*6+other]
		if edge >= 0 && colors[edge] == color do return false
	}
	return true
}

@(export)
misra_gries_edge_coloring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < 1 || input[0] > 6 || input[1] < 0 || input[1] > 6 do return -1
	vertices := int(input[0])
	edge_count := int(input[1])
	if length != c.size_t(2+2*edge_count) do return -1
	left: [6]int = {}
	right: [6]int = {}
	degree: [6]int = {}
	edge_at: [36]int = {}
	for i in 0..<36 { edge_at[i] = -1 }
	for edge in 0..<edge_count {
		a, b := input[2+2*edge], input[3+2*edge]
		if a < 0 || b < 0 || a >= i64(vertices) || b >= i64(vertices) || a == b do return -1
		u, v := int(a), int(b)
		if u > v { u, v = v, u }
		if edge_at[u*6+v] >= 0 do return -1
		left[edge] = u; right[edge] = v
		edge_at[u*6+v] = edge; edge_at[v*6+u] = edge
		degree[u] += 1; degree[v] += 1
	}
	delta := 0
	for vertex in 0..<vertices { if degree[vertex] > delta { delta = degree[vertex] } }
	palette := 0
	if edge_count > 0 { palette = delta + 1 }
	colors: [6]i64 = {}
	for edge in 0..<6 { colors[edge] = -1 }

	for edge in 0..<edge_count {
		center := left[edge]
		fan: [6]int = {}
		fan_count := 1
		fan[0] = right[edge]
		for {
			tail := fan[fan_count-1]
			extended := false
			for neighbor in 0..<vertices {
				candidate := edge_at[center*6+neighbor]
				if candidate < 0 || colors[candidate] < 0 do continue
				present := false
				for i in 0..<fan_count { if fan[i] == neighbor { present = true } }
				if present || !mg_free(tail, colors[candidate], vertices, edge_at, colors) do continue
				fan[fan_count] = neighbor; fan_count += 1; extended = true; break
			}
			if !extended do break
		}
		color_c: i64 = 0
		for color_c < i64(palette) && !mg_free(center, color_c, vertices, edge_at, colors) { color_c += 1 }
		color_d: i64 = 0
		for color_d < i64(palette) && !mg_free(fan[fan_count-1], color_d, vertices, edge_at, colors) { color_d += 1 }
		if color_c >= i64(palette) || color_d >= i64(palette) do return -1

		path: [6]int = {}
		path_count := 0
		current := center
		wanted := color_d
		visited: [6]bool = {}
		visited[current] = true
		for step in 0..<vertices {
			path_edge := -1
			next := 0
			for neighbor in 0..<vertices {
				candidate := edge_at[current*6+neighbor]
				if candidate >= 0 && colors[candidate] == wanted { path_edge = candidate; next = neighbor; break }
			}
			if path_edge < 0 || visited[next] do break
			path[path_count] = path_edge; path_count += 1
			visited[next] = true; current = next
			if wanted == color_d { wanted = color_c } else { wanted = color_d }
		}
		for i in 0..<path_count {
			path_edge := path[i]
			if colors[path_edge] == color_d { colors[path_edge] = color_c } else { colors[path_edge] = color_d }
		}

		prefix_end := fan_count
		for i in 0..<fan_count {
			if mg_free(fan[i], color_d, vertices, edge_at, colors) { prefix_end = i; break }
		}
		if prefix_end == fan_count do return -1
		shifted: [6]i64 = {}
		for i in 0..<prefix_end { shifted[i] = colors[edge_at[center*6+fan[i+1]]] }
		for i in 0..<prefix_end { colors[edge_at[center*6+fan[i]]] = shifted[i] }
		colors[edge_at[center*6+fan[prefix_end]]] = color_d
	}
	signature: i64 = 0
	place: i64 = 1
	for edge in 0..<edge_count { signature += colors[edge]*place; place *= 8 }
	return i64(palette)*262144 + signature
}
