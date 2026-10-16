module problem107

const max_vertices = 40
const max_edge_weight = i64(999)

fn edge_weight(input &i64, left int, right int) i64 {
	if left == right { return -1 }
	row := if left > right { left } else { right }
	column := if left > right { right } else { left }
	return unsafe { input[1 + row * (row - 1) / 2 + column] }
}

@[export: 'problem107']
pub fn problem107(input &i64, length usize) i64 {
	if length < 1 { return -1 }
	vertex_count_value := unsafe { input[0] }
	if vertex_count_value < 1 || vertex_count_value > i64(max_vertices) { return -1 }
	vertex_count := int(vertex_count_value)
	if length != usize(1 + vertex_count * (vertex_count - 1) / 2) { return -1 }

	mut total_weight := i64(0)
	for index in 1 .. int(length) {
		weight := unsafe { input[index] }
		if weight < -1 || weight > max_edge_weight { return -1 }
		if weight >= 0 { total_weight += weight }
	}
	mut selected := [max_vertices]bool{}
	mut best_weight := [max_vertices]i64{}
	for vertex in 0 .. vertex_count { best_weight[vertex] = max_edge_weight + 1 }
	best_weight[0] = 0
	mut tree_weight := i64(0)
	for _ in 0 .. vertex_count {
		mut next_vertex := vertex_count
		mut next_weight := max_edge_weight + 1
		for vertex in 0 .. vertex_count {
			if !selected[vertex] && best_weight[vertex] < next_weight {
				next_vertex = vertex
				next_weight = best_weight[vertex]
			}
		}
		if next_vertex == vertex_count { return -1 }
		selected[next_vertex] = true
		tree_weight += next_weight
		for vertex in 0 .. vertex_count {
			if selected[vertex] { continue }
			weight := edge_weight(input, next_vertex, vertex)
			if weight >= 0 && weight < best_weight[vertex] { best_weight[vertex] = weight }
		}
	}
	return total_weight - tree_weight
}
