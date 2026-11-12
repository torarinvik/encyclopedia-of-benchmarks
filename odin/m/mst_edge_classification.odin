package mst_edge_classification

import "core:c"

MAX_VERTICES :: 12
MAX_EDGES :: 24
MAX_INPUT_LENGTH :: 2 + 3 * MAX_EDGES + 1

find_root :: proc(parent: [^]int, vertex: int) -> int {
	root := vertex
	for parent[root] != root { root = parent[root] }
	current := vertex
	for parent[current] != current {
		next := parent[current]
		parent[current] = root
		current = next
	}
	return root
}

join_roots :: proc(parent: [^]int, left, right: int) {
	a := find_root(parent, left)
	b := find_root(parent, right)
	if a != b do parent[b] = a
}

alternative_path_exists :: proc(left, right, edge_id: [^]int, edge_count: int,
	omitted, source, target: int) -> bool {
	seen: [MAX_VERTICES]bool
	queue: [MAX_VERTICES]int
	head, tail := 0, 0
	seen[source] = true
	queue[tail] = source
	tail += 1
	for head < tail {
		vertex := queue[head]
		head += 1
		if vertex == target do return true
		for edge := 0; edge < edge_count; edge += 1 {
			if edge_id[edge] == omitted do continue
			neighbor := -1
			if left[edge] == vertex do neighbor = right[edge]
			else if right[edge] == vertex do neighbor = left[edge]
			if neighbor >= 0 && !seen[neighbor] {
				seen[neighbor] = true
				queue[tail] = neighbor
				tail += 1
			}
		}
	}
	return false
}

@(export)
mst_edge_classification :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	vertex_count := int(input[0])
	edge_count := int(input[1])
	if int(length) != 2 + 3 * edge_count do return -1

	var left, right, weight, order: [MAX_EDGES]int
	var classes: [MAX_EDGES]u8
	for edge := 0; edge < edge_count; edge += 1 {
		u := input[2 + 3 * edge]
		v := input[3 + 3 * edge]
		w := input[4 + 3 * edge]
		if u < 0 || u >= v || v >= i64(vertex_count) || w < 0 || w > 20 do return -1
		left[edge], right[edge], weight[edge], order[edge] = int(u), int(v), int(w), edge
		for prior := 0; prior < edge; prior += 1 {
			if left[prior] == left[edge] && right[prior] == right[edge] do return -1
		}
	}
	for i := 1; i < edge_count; i += 1 {
		item := order[i]
		j := i
		for j > 0 && (weight[order[j-1]] > weight[item] ||
				(weight[order[j-1]] == weight[item] && order[j-1] > item)) {
			order[j] = order[j-1]
			j -= 1
		}
		order[j] = item
	}

	var parent: [MAX_VERTICES]int
	for vertex := 0; vertex < vertex_count; vertex += 1 do parent[vertex] = vertex
	start := 0
	for start < edge_count {
		stop := start + 1
		group_weight := weight[order[start]]
		for stop < edge_count && weight[order[stop]] == group_weight do stop += 1
		var q_left, q_right, q_id: [MAX_EDGES]int
		q_count := 0
		for pos := start; pos < stop; pos += 1 {
			id := order[pos]
			a := find_root(&parent[0], left[id])
			b := find_root(&parent[0], right[id])
			if a != b {
				q_left[q_count], q_right[q_count], q_id[q_count] = a, b, id
				q_count += 1
			}
		}
		for edge := 0; edge < q_count; edge += 1 {
			if alternative_path_exists(&q_left[0], &q_right[0], &q_id[0], q_count,
					q_id[edge], q_left[edge], q_right[edge]) {
				classes[q_id[edge]] = 1
			} else {
				classes[q_id[edge]] = 2
			}
		}
		for pos := start; pos < stop; pos += 1 {
			id := order[pos]
			join_roots(&parent[0], left[id], right[id])
		}
		start = stop
	}
	representative := find_root(&parent[0], 0)
	for vertex := 1; vertex < vertex_count; vertex += 1 {
		if find_root(&parent[0], vertex) != representative do return -1
	}
	if output_capacity < c.size_t(edge_count) || (edge_count > 0 && output == nil) do return -2
	for edge := 0; edge < edge_count; edge += 1 do output[edge] = classes[edge]
	return i64(edge_count)
}
