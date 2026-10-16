package problem107

import "core:c"

const MAX_VERTICES = 40
const MAX_EDGE_WEIGHT: i64 = 999

edge_weight :: proc(input: [^]i64, left, right: int) -> i64 {
	if left == right do return -1
	row := max(left, right)
	column := min(left, right)
	return input[1 + row * (row - 1) / 2 + column]
}

@(export)
problem107 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	vertex_count_value := input[0]
	if vertex_count_value < 1 || vertex_count_value > i64(MAX_VERTICES) do return -1
	vertex_count := int(vertex_count_value)
	if length != c.size_t(1 + vertex_count * (vertex_count - 1) / 2) do return -1

	total_weight := i64(0)
	for index := 1; index < int(length); index += 1 {
		if input[index] < -1 || input[index] > MAX_EDGE_WEIGHT do return -1
		if input[index] >= 0 { total_weight += input[index] }
	}
	selected: [MAX_VERTICES]bool
	best_weight: [MAX_VERTICES]i64
	for vertex := 0; vertex < vertex_count; vertex += 1 { selected[vertex] = false; best_weight[vertex] = MAX_EDGE_WEIGHT + 1 }
	best_weight[0] = 0
	tree_weight := i64(0)
	for iteration := 0; iteration < vertex_count; iteration += 1 {
		next_vertex := vertex_count
		next_weight := i64(MAX_EDGE_WEIGHT + 1)
		for vertex := 0; vertex < vertex_count; vertex += 1 {
			if !selected[vertex] && best_weight[vertex] < next_weight { next_vertex = vertex; next_weight = best_weight[vertex] }
		}
		if next_vertex == vertex_count do return -1
		selected[next_vertex] = true
		tree_weight += next_weight
		for vertex := 0; vertex < vertex_count; vertex += 1 {
			if selected[vertex] do continue
			weight := edge_weight(input, next_vertex, vertex)
			if weight >= 0 && weight < best_weight[vertex] { best_weight[vertex] = weight }
		}
	}
	return total_weight - tree_weight
}
