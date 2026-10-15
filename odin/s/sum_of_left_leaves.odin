package sum_of_left_leaves

import "core:c"

MAX_NODE_COUNT :: 1023
ERROR_SENTINEL :: i64(-2_000_000_000)

visit :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		node: i64, is_left: bool) -> i64 {
	if node == -1 do return 0
	if node < 0 || u64(node) >= u64(node_count) do return ERROR_SENTINEL
	index := c.size_t(node)
	value := nodes[3 * index]
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if value < -1000 || value > 1000 || left < -1 ||
		(left >= 0 && u64(left) >= u64(node_count)) || right < -1 ||
		(right >= 0 && u64(right) >= u64(node_count)) {
		return ERROR_SENTINEL
	}
	if left == -1 && right == -1 {
		if is_left do return value
		return 0
	}
	left_sum := visit(nodes, node_count, left, true)
	if left_sum == ERROR_SENTINEL do return ERROR_SENTINEL
	right_sum := visit(nodes, node_count, right, false)
	if right_sum == ERROR_SENTINEL do return ERROR_SENTINEL
	return left_sum + right_sum
}

@(export)
sum_of_left_leaves :: proc "contextless" (nodes: [^]i64,
		node_count: c.size_t, root_index: i64) -> i64 {
	if node_count > MAX_NODE_COUNT do return -1
	if node_count == 0 {
		if root_index == -1 do return 0
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) {
		return -1
	}
	result := visit(nodes, node_count, root_index, false)
	if result == ERROR_SENTINEL do return -1
	return result
}
