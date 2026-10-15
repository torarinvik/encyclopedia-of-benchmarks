package diameter_of_binary_tree

import "core:c"

MAX_NODE_COUNT :: 1023
ERROR_SENTINEL :: i64(-2_000_000_000)

height_and_check :: proc "contextless" (nodes: [^]i64, count: c.size_t,
		node: i64, seen: [^]bool, visited: ^int) -> i64 {
	if node == -1 do return 0
	if node < 0 || u64(node) >= u64(count) do return ERROR_SENTINEL
	index := c.size_t(node)
	if seen[index] do return ERROR_SENTINEL
	seen[index] = true
	visited^ += 1
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if left < -1 || right < -1 || (left >= 0 && u64(left) >= u64(count)) ||
		(right >= 0 && u64(right) >= u64(count)) do return ERROR_SENTINEL
	left_height := height_and_check(nodes, count, left, seen, visited)
	if left_height == ERROR_SENTINEL do return ERROR_SENTINEL
	right_height := height_and_check(nodes, count, right, seen, visited)
	if right_height == ERROR_SENTINEL do return ERROR_SENTINEL
	return 1 + max(left_height, right_height)
}

@(export)
diameter_of_binary_tree :: proc "contextless" (nodes: [^]i64,
		node_count: c.size_t, root_index: i64) -> i64 {
	if nodes == nil || node_count == 0 || node_count > MAX_NODE_COUNT ||
		root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	seen: [MAX_NODE_COUNT]bool
	for index := 0; index < int(node_count); index += 1 { seen[index] = false }
	visited := 1
	root := c.size_t(root_index)
	seen[root] = true
	left, right := nodes[3 * root + 1], nodes[3 * root + 2]
	if left < -1 || right < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		(right >= 0 && u64(right) >= u64(node_count)) do return -1
	left_height := height_and_check(nodes, node_count, left, &seen[0], &visited)
	if left_height == ERROR_SENTINEL do return -1
	right_height := height_and_check(nodes, node_count, right, &seen[0], &visited)
	if right_height == ERROR_SENTINEL || visited != int(node_count) do return -1
	return left_height + right_height + 1
}
