package minimum_spanning_tree_kruskal

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 4096
MAX_INPUT_LENGTH :: 2 + 3 * MAX_EDGES

edge_less :: proc "contextless" (input: [^]i64, left, right: int) -> bool {
	left_weight := input[2+3*left+2]
	right_weight := input[2+3*right+2]
	return left_weight < right_weight || (left_weight == right_weight && left < right)
}

sift_down :: proc "contextless" (input: [^]i64, order: [^]int, root_start, ending: int) {
	root := root_start
	for root*2+1 < ending {
		child := root*2+1
		if child+1 < ending && edge_less(input, order[child], order[child+1]) do child += 1
		if !edge_less(input, order[root], order[child]) do break
		order[root], order[child] = order[child], order[root]
		root = child
	}
}

heap_sort :: proc "contextless" (input: [^]i64, order: [^]int, count: int) {
	start := count/2
	for start > 0 {
		start -= 1
		sift_down(input, order, start, count)
	}
	ending := count
	for ending > 1 {
		ending -= 1
		order[0], order[ending] = order[ending], order[0]
		sift_down(input, order, 0, ending)
	}
}

find_root :: proc "contextless" (parent: [^]int, node_start: int) -> int {
	node := node_start
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u64(8*byte))
	}
}

@(export)
minimum_spanning_tree_kruskal :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_vertices, raw_edges := input[0], input[1]
	if raw_vertices < 0 || raw_vertices > i64(MAX_VERTICES) || raw_edges < 0 || raw_edges > i64(MAX_EDGES) do return -1
	vertex_count, edge_count := int(raw_vertices), int(raw_edges)
	if length != c.size_t(2+3*edge_count) do return -1

	order: [MAX_EDGES]int
	for index := 0; index < edge_count; index += 1 {
		offset := 2+3*index
		u, v := input[offset], input[offset+1]
		if u < 0 || u >= raw_vertices || v < 0 || v >= raw_vertices do return -1
		order[index] = index
	}
	heap_sort(input, &order[0], edge_count)

	parent: [MAX_VERTICES]int
	for vertex := 0; vertex < vertex_count; vertex += 1 do parent[vertex] = vertex
	accepted: [MAX_VERTICES]int
	accepted_count := 0
	for index := 0; index < edge_count; index += 1 {
		edge_index := order[index]
		offset := 2+3*edge_index
		left_root := find_root(&parent[0], int(input[offset]))
		right_root := find_root(&parent[0], int(input[offset+1]))
		if left_root != right_root {
			accepted[accepted_count] = edge_index
			accepted_count += 1
			parent[left_root] = right_root
		}
	}

	byte_count := accepted_count*24
	if output == nil || capacity < c.size_t(byte_count) do return -2
	for index := 0; index < accepted_count; index += 1 {
		input_offset := 2+3*accepted[index]
		output_offset := index*24
		put_i64_le(output, output_offset, input[input_offset])
		put_i64_le(output, output_offset+8, input[input_offset+1])
		put_i64_le(output, output_offset+16, input[input_offset+2])
	}
	return i64(byte_count)
}
