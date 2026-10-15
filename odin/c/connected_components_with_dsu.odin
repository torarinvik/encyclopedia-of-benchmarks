package connected_components_with_dsu

import "core:c"

MAX_NODE_COUNT :: 256
MAX_EDGE_COUNT :: 2047
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGE_COUNT

find_root :: proc "contextless" (parent: [^]int, node: int) -> int {
	current := node
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}

@(export)
connected_components_with_dsu :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_NODE_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT do return -1
	node_count := int(input[0])
	edge_count := int(input[1])
	if int(length) != 2 + 2 * edge_count do return -1

	parent := [MAX_NODE_COUNT + 1]int{}
	set_size := [MAX_NODE_COUNT + 1]int{}
	for node := 1; node <= node_count; node += 1 {
		parent[node] = node
		set_size[node] = 1
	}
	component_count := node_count
	for edge := 0; edge < edge_count; edge += 1 {
		left_arg := input[2 + 2 * edge]
		right_arg := input[3 + 2 * edge]
		if left_arg < 1 || left_arg > i64(node_count) || right_arg < 1 || right_arg > i64(node_count) do return -1
		left := find_root(&parent[0], int(left_arg))
		right := find_root(&parent[0], int(right_arg))
		if left == right do continue
		if set_size[left] < set_size[right] {
			temporary := left
			left = right
			right = temporary
		}
		parent[right] = left
		set_size[left] += set_size[right]
		component_count -= 1
	}
	return i64(component_count)
}
