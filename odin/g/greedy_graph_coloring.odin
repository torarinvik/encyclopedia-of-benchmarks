package greedy_graph_coloring

import "core:c"

@(export)
greedy_graph_coloring :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 15 do return -1
	count_value := values[0]
	if count_value < 0 || count_value > 14 || length != c.size_t(count_value + 1) do return -1
	count := int(count_value)
	limit := (i64(1) << count) - 1
	adjacency: [14]i64
	degree: [14]int
	order: [14]int
	colors: [14]int
	for vertex := 0; vertex < count; vertex += 1 {
		mask := values[1 + vertex]
		if mask < 0 || mask > limit || (mask & (i64(1) << vertex)) != 0 do return -1
		adjacency[vertex] = mask
		order[vertex] = vertex
		remaining := mask
		for remaining != 0 { remaining &= remaining - 1; degree[vertex] += 1 }
	}
	for vertex := 0; vertex < count; vertex += 1 {
		for other := 0; other < count; other += 1 {
			if ((adjacency[vertex] >> other) & 1) != ((adjacency[other] >> vertex) & 1) do return -1
		}
	}
	for index := 1; index < count; index += 1 {
		current := order[index]
		position := index
		for position > 0 && degree[order[position - 1]] < degree[current] {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = current
	}
	color_count := 0
	for position := 0; position < count; position += 1 {
		vertex := order[position]
		used: i64 = 0
		for other := 0; other < count; other += 1 {
			if (adjacency[vertex] & (i64(1) << other)) != 0 && colors[other] != 0 do used |= i64(1) << colors[other]
		}
		color := 1
		for (used & (i64(1) << color)) != 0 { color += 1 }
		colors[vertex] = color
		if color > color_count do color_count = color
	}
	packed := i64(color_count)
	for vertex := 0; vertex < count; vertex += 1 { packed |= i64(colors[vertex]) << (4 * (vertex + 1)) }
	return packed
}
