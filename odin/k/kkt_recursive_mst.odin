package kkt_recursive_mst

import "core:c"

MAX_VERTICES :: 16
MAX_EDGES :: 16
MAX_INPUT_LENGTH :: c.size_t(52)

Edge :: struct {
	u: int,
	v: int,
	weight: i64,
	original_id: int,
}

edge_less :: proc "contextless" (left, right: Edge) -> bool {
	return left.weight < right.weight || left.weight == right.weight && left.original_id < right.original_id
}

find_root :: proc "contextless" (parent: ^[MAX_VERTICES]int, start: int) -> int {
	root := start
	for parent[root] != root { root = parent[root] }
	vertex := start
	for parent[vertex] != vertex {
		next := parent[vertex]
		parent[vertex] = root
		vertex = next
	}
	return root
}

splitmix64_next :: proc "contextless" (state: ^u64) -> u64 {
	state^ += 0x9E3779B97F4A7C15
	value := state^
	value = (value ^ (value >> 30)) * 0xBF58476D1CE4E5B9
	value = (value ^ (value >> 27)) * 0x94D049BB133111EB
	return value ^ (value >> 31)
}

boruvka_phase :: proc "contextless" (vertex_count, edge_count: ^int,
		edges: ^[MAX_EDGES]Edge) -> u64 {
	var selected: [MAX_EDGES]bool
	for vertex := 0; vertex < vertex_count^; vertex += 1 {
		best := -1
		for edge_index := 0; edge_index < edge_count^; edge_index += 1 {
			edge := edges[edge_index]
			if edge.u != vertex && edge.v != vertex do continue
			if best < 0 || edge_less(edge, edges[best]) { best = edge_index }
		}
		if best >= 0 { selected[best] = true }
	}

	var parent: [MAX_VERTICES]int
	for vertex := 0; vertex < vertex_count^; vertex += 1 { parent[vertex] = vertex }
	selected_mask: u64 = 0
	for edge_index := 0; edge_index < edge_count^; edge_index += 1 {
		if !selected[edge_index] do continue
		edge := edges[edge_index]
		selected_mask |= u64(1) << u32(edge.original_id)
		left := find_root(&parent, edge.u)
		right := find_root(&parent, edge.v)
		if left != right { parent[right] = left }
	}

	var root_to_new: [MAX_VERTICES]int
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 { root_to_new[vertex] = -1 }
	var remapped: [MAX_VERTICES]int
	new_vertex_count := 0
	for vertex := 0; vertex < vertex_count^; vertex += 1 {
		root := find_root(&parent, vertex)
		if root_to_new[root] < 0 {
			root_to_new[root] = new_vertex_count
			new_vertex_count += 1
		}
		remapped[vertex] = root_to_new[root]
	}

	var reduced: [MAX_EDGES]Edge
	reduced_count := 0
	for edge_index := 0; edge_index < edge_count^; edge_index += 1 {
		edge := edges[edge_index]
		left, right := remapped[edge.u], remapped[edge.v]
		if left == right do continue
		if left > right { left, right = right, left }
		edge.u, edge.v = left, right
		parallel := -1
		for prior := 0; prior < reduced_count; prior += 1 {
			if reduced[prior].u == left && reduced[prior].v == right { parallel = prior; break }
		}
		if parallel >= 0 {
			if edge_less(edge, reduced[parallel]) { reduced[parallel] = edge }
		} else {
			reduced[reduced_count] = edge
			reduced_count += 1
		}
	}

	vertex_count^ = new_vertex_count
	edge_count^ = reduced_count
	edges^ = reduced
	return selected_mask
}

path_maximum :: proc "contextless" (edge_count: int, edges: ^[MAX_EDGES]Edge,
		forest_mask: u64, source, target: int, max_weight, max_id: ^i64) -> bool {
	var parent_vertex: [MAX_VERTICES]int
	var parent_edge: [MAX_VERTICES]int
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 {
		parent_vertex[vertex] = -1
		parent_edge[vertex] = -1
	}
	var queue: [MAX_VERTICES]int
	head, tail := 0, 1
	queue[0] = source
	parent_vertex[source] = source
	for head < tail && parent_vertex[target] < 0 {
		current := queue[head]
		head += 1
		for edge_index := 0; edge_index < edge_count; edge_index += 1 {
			edge := edges[edge_index]
			if (forest_mask & (u64(1) << u32(edge.original_id))) == 0 do continue
			next := -1
			if edge.u == current { next = edge.v } else if edge.v == current { next = edge.u }
			if next >= 0 && parent_vertex[next] < 0 {
				parent_vertex[next] = current
				parent_edge[next] = edge_index
				queue[tail] = next
				tail += 1
			}
		}
	}
	if parent_vertex[target] < 0 do return false

	max_weight^ = -1
	max_id^ = -1
	current := target
	for current != source {
		edge := edges[parent_edge[current]]
		if edge.weight > max_weight^ || edge.weight == max_weight^ && i64(edge.original_id) > max_id^ {
			max_weight^ = edge.weight
			max_id^ = i64(edge.original_id)
		}
		current = parent_vertex[current]
	}
	return true
}

recursive_mst :: proc "contextless" (initial_vertex_count, initial_edge_count: int,
		initial_edges: [MAX_EDGES]Edge, state: ^u64) -> u64 {
	if initial_edge_count == 0 do return 0
	vertex_count, edge_count := initial_vertex_count, initial_edge_count
	edges := initial_edges
	selected_mask: u64 = 0
	for _ in 0..<2 {
		selected_mask |= boruvka_phase(&vertex_count, &edge_count, &edges)
		if edge_count == 0 do return selected_mask
	}

	for index := 1; index < edge_count; index += 1 {
		edge := edges[index]
		position := index
		for position > 0 && edge_less(edge, edges[position-1]) {
			edges[position] = edges[position-1]
			position -= 1
		}
		edges[position] = edge
	}

	var sample_edges: [MAX_EDGES]Edge
	sample_count := 0
	for edge_index := 0; edge_index < edge_count; edge_index += 1 {
		if (splitmix64_next(state) & 1) != 0 {
			sample_edges[sample_count] = edges[edge_index]
			sample_count += 1
		}
	}
	forest_mask := recursive_mst(vertex_count, sample_count, sample_edges, state)

	var light_edges: [MAX_EDGES]Edge
	light_count := 0
	for edge_index := 0; edge_index < edge_count; edge_index += 1 {
		edge := edges[edge_index]
		in_forest := (forest_mask & (u64(1) << u32(edge.original_id))) != 0
		heavy := false
		if !in_forest {
			var max_weight, max_id: i64
			if path_maximum(edge_count, &edges, forest_mask, edge.u, edge.v, &max_weight, &max_id) {
				heavy = edge.weight > max_weight || edge.weight == max_weight && i64(edge.original_id) > max_id
			}
		}
		if !heavy { light_edges[light_count] = edge; light_count += 1 }
	}
	return selected_mask | recursive_mst(vertex_count, light_count, light_edges, state)
}

@(export)
kkt_recursive_mst :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	vertex_value, edge_value, seed_value := input[0], input[1], input[2]
	if vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES || seed_value < 0 do return -1
	vertex_count, edge_count := int(vertex_value), int(edge_value)
	if length != c.size_t(3+3*edge_count) do return -1

	var edges: [MAX_EDGES]Edge
	for edge_index := 0; edge_index < edge_count; edge_index += 1 {
		u_value, v_value, weight := input[3+3*edge_index], input[4+3*edge_index], input[5+3*edge_index]
		if u_value < 0 || v_value <= u_value || v_value >= vertex_value || weight < 0 || weight > 255 do return -1
		u, v := int(u_value), int(v_value)
		for prior := 0; prior < edge_index; prior += 1 {
			if edges[prior].u == u && edges[prior].v == v do return -1
		}
		edges[edge_index] = Edge{u = u, v = v, weight = weight, original_id = edge_index}
	}
	state := u64(seed_value)
	return i64(recursive_mst(vertex_count, edge_count, edges, &state))
}
