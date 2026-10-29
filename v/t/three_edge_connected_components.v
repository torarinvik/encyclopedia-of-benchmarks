module three_edge_connected_components

const max_vertices = 8
const max_edges = 32
const max_input_length = 2 + 2 * max_edges

struct Edge {
	u int
	v int
}

struct ComponentRefinement {
	mut:
	same [max_vertices * max_vertices]bool
}

fn refine_for_removal(edges []Edge, vertex_count int, edge_count int, removed_first int, removed_second int, mut same ComponentRefinement) {
	mut component := [max_vertices]int{}
	for vertex in 0 .. vertex_count { component[vertex] = -1 }
	mut queue := [max_vertices]int{}
	mut next_component := 0
	for start in 0 .. vertex_count {
		if component[start] >= 0 { continue }
		mut head := 0
		mut tail := 0
		component[start] = next_component
		queue[tail] = start
		tail++
		for head < tail {
			vertex := queue[head]
			head++
			for edge_id in 0 .. edge_count {
				if edge_id == removed_first || edge_id == removed_second { continue }
				edge := edges[edge_id]
				mut neighbor := -1
				if edge.u == vertex { neighbor = edge.v } else if edge.v == vertex { neighbor = edge.u }
				if neighbor >= 0 && component[neighbor] < 0 {
					component[neighbor] = next_component
					queue[tail] = neighbor
					tail++
				}
			}
		}
		next_component++
	}
	for first in 0 .. vertex_count {
		for second in first + 1 .. vertex_count {
			if component[first] != component[second] {
				same.same[first * max_vertices + second] = false
				same.same[second * max_vertices + first] = false
			}
		}
	}
}

@[export: 'three_edge_connected_components']
pub fn three_edge_connected_components(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_input_length { return -1 }
	if unsafe { values[0] < 1 || values[0] > max_vertices || values[1] < 0 || values[1] > max_edges } { return -1 }
	vertex_count := int(unsafe { values[0] })
	edge_count := int(unsafe { values[1] })
	if length != 2 + 2 * edge_count { return -1 }
	mut edges := [max_edges]Edge{}
	for edge_id in 0 .. edge_count {
		from_value := unsafe { values[2 + 2 * edge_id] }
		to_value := unsafe { values[3 + 2 * edge_id] }
		if from_value < 0 || from_value >= vertex_count || to_value < 0 || to_value >= vertex_count { return -1 }
		edges[edge_id] = Edge{u: int(from_value), v: int(to_value)}
	}

	mut same := ComponentRefinement{}
	for index in 0 .. max_vertices * max_vertices { same.same[index] = true }
	edge_view := edges[..edge_count]
	refine_for_removal(edge_view, vertex_count, edge_count, -1, -1, mut same)
	for first in 0 .. edge_count {
		refine_for_removal(edge_view, vertex_count, edge_count, first, -1, mut same)
		for second in first + 1 .. edge_count {
			refine_for_removal(edge_view, vertex_count, edge_count, first, second, mut same)
		}
	}

	mut labels := [max_vertices]int{}
	for vertex in 0 .. vertex_count { labels[vertex] = -1 }
	mut next_label := 0
	for first in 0 .. vertex_count {
		if labels[first] >= 0 { continue }
		for vertex in first .. vertex_count {
			if labels[vertex] < 0 && same.same[first * max_vertices + vertex] { labels[vertex] = next_label }
		}
		next_label++
	}
	mut encoded := i64(0)
	mut place := i64(1)
	for vertex in 0 .. vertex_count {
		encoded += i64(labels[vertex]) * place
		place *= 8
	}
	return encoded
}
