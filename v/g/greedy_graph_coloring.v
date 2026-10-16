module greedy_graph_coloring

const max_vertices = 14

@[export: 'greedy_graph_coloring']
pub fn greedy_graph_coloring(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_vertices + 1 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > max_vertices || length != usize(count_value + 1) { return -1 }
	count := int(count_value)
	limit := (i64(1) << count) - 1
	mut adjacency := [max_vertices]i64{}
	mut degree := [max_vertices]int{}
	mut order := [max_vertices]int{}
	mut colors := [max_vertices]int{}
	for vertex in 0 .. count {
		mask := unsafe { values[1 + vertex] }
		if mask < 0 || mask > limit || (mask & (i64(1) << vertex)) != 0 { return -1 }
		adjacency[vertex] = mask
		order[vertex] = vertex
		mut remaining := mask
		for remaining != 0 { remaining &= remaining - 1; degree[vertex]++ }
	}
	for vertex in 0 .. count {
		for other in 0 .. count {
			if ((adjacency[vertex] >> other) & 1) != ((adjacency[other] >> vertex) & 1) { return -1 }
		}
	}
	for index in 1 .. count {
		current := order[index]
		mut position := index
		for position > 0 && degree[order[position - 1]] < degree[current] {
			order[position] = order[position - 1]
			position--
		}
		order[position] = current
	}
	mut color_count := 0
	for position in 0 .. count {
		vertex := order[position]
		mut used := [max_vertices + 1]bool{}
		for other in 0 .. count {
			if (adjacency[vertex] & (i64(1) << other)) != 0 && colors[other] != 0 { used[colors[other]] = true }
		}
		mut color := 1
		for used[color] { color++ }
		colors[vertex] = color
		if color > color_count { color_count = color }
	}
	mut packed := i64(color_count)
	for vertex in 0 .. count { packed |= i64(colors[vertex]) << (4 * (vertex + 1)) }
	return packed
}
