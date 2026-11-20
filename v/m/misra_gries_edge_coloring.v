module misra_gries_edge_coloring

const max_length = 15

fn mg_free(vertex int, color i64, vertices int, edge_at [36]int, colors [6]i64) bool {
	for other in 0 .. vertices {
		edge := edge_at[vertex * 6 + other]
		if edge >= 0 && colors[edge] == color { return false }
	}
	return true
}

@[export: 'misra_gries_edge_coloring']
pub fn misra_gries_edge_coloring(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length { return -1 }
		if input[0] < 1 || input[0] > 6 || input[1] < 0 || input[1] > 6 { return -1 }
		vertices := int(input[0])
		edge_count := int(input[1])
		if length != usize(2 + 2 * edge_count) { return -1 }
		mut left := [6]int{}
		mut right := [6]int{}
		mut degree := [6]int{}
		mut edge_at := [36]int{}
		for i in 0 .. 36 { edge_at[i] = -1 }
		for edge in 0 .. edge_count {
			a := input[2 + 2 * edge]
			b := input[3 + 2 * edge]
			if a < 0 || b < 0 || a >= i64(vertices) || b >= i64(vertices) || a == b { return -1 }
			u := int(a)
			v := int(b)
			if u > v { u, v = v, u }
			if edge_at[u * 6 + v] >= 0 { return -1 }
			left[edge] = u
			right[edge] = v
			edge_at[u * 6 + v] = edge
			edge_at[v * 6 + u] = edge
			degree[u]++
			degree[v]++
		}
		mut delta := 0
		for vertex in 0 .. vertices { if degree[vertex] > delta { delta = degree[vertex] } }
		palette := if edge_count == 0 { 0 } else { delta + 1 }
		mut colors := [6]i64{}
		for edge in 0 .. 6 { colors[edge] = -1 }

		for edge in 0 .. edge_count {
			center := left[edge]
			mut fan := [6]int{}
			mut fan_count := 1
			fan[0] = right[edge]
			for {
				tail := fan[fan_count - 1]
				mut extended := false
				for neighbor in 0 .. vertices {
					candidate := edge_at[center * 6 + neighbor]
					if candidate < 0 || colors[candidate] < 0 { continue }
					mut present := false
					for i in 0 .. fan_count { if fan[i] == neighbor { present = true } }
					if present || !mg_free(tail, colors[candidate], vertices, edge_at, colors) { continue }
					fan[fan_count] = neighbor
					fan_count++
					extended = true
					break
				}
				if !extended { break }
			}
			mut color_c := i64(0)
			for color_c < i64(palette) && !mg_free(center, color_c, vertices, edge_at, colors) { color_c++ }
			mut color_d := i64(0)
			for color_d < i64(palette) && !mg_free(fan[fan_count - 1], color_d, vertices, edge_at, colors) { color_d++ }
			if color_c >= i64(palette) || color_d >= i64(palette) { return -1 }

			mut path := [6]int{}
			mut path_count := 0
			mut current := center
			mut wanted := color_d
			mut visited := [6]bool{}
			visited[current] = true
			for step in 0 .. vertices {
				mut path_edge := -1
				mut next := 0
				for neighbor in 0 .. vertices {
					candidate := edge_at[current * 6 + neighbor]
					if candidate >= 0 && colors[candidate] == wanted { path_edge = candidate; next = neighbor; break }
				}
				if path_edge < 0 || visited[next] { break }
				path[path_count] = path_edge
				path_count++
				visited[next] = true
				current = next
				wanted = if wanted == color_d { color_c } else { color_d }
			}
			for i in 0 .. path_count {
				path_edge := path[i]
				colors[path_edge] = if colors[path_edge] == color_d { color_c } else { color_d }
			}

			mut prefix_end := fan_count
			for i in 0 .. fan_count {
				if mg_free(fan[i], color_d, vertices, edge_at, colors) { prefix_end = i; break }
			}
			if prefix_end == fan_count { return -1 }
			mut shifted := [6]i64{}
			for i in 0 .. prefix_end { shifted[i] = colors[edge_at[center * 6 + fan[i + 1]]] }
			for i in 0 .. prefix_end { colors[edge_at[center * 6 + fan[i]]] = shifted[i] }
			colors[edge_at[center * 6 + fan[prefix_end]]] = color_d
		}
		mut signature := i64(0)
		mut place := i64(1)
		for edge in 0 .. edge_count { signature += colors[edge] * place; place *= 8 }
		return i64(palette) * 262144 + signature
	}
}
