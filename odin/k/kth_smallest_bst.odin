package kth_smallest_bst

import "core:c"

MAX_NODE_COUNT :: 1023
MAX_VALUE :: 10000
INVALID_TREE_RESULT :: i64(-9223372036854775807 - 1)

kth_visit :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		node: i64, remaining: ^i64) -> i64 {
	if node == -1 do return -1
	if node < 0 || u64(node) >= u64(node_count) do return INVALID_TREE_RESULT
	index := c.size_t(node)
	value := nodes[3 * index]
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if value < 0 || value > MAX_VALUE || left < -1 || right < -1 ||
		(left >= 0 && u64(left) >= u64(node_count)) ||
		(right >= 0 && u64(right) >= u64(node_count)) {
		return INVALID_TREE_RESULT
	}
	left_result := kth_visit(nodes, node_count, left, remaining)
	if left_result >= 0 || left_result == INVALID_TREE_RESULT do return left_result
	remaining^ -= 1
	if remaining^ == 0 do return value
	return kth_visit(nodes, node_count, right, remaining)
}

@(export)
kth_smallest_bst :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		root_index, k: i64) -> i64 {
	if node_count == 0 || node_count > MAX_NODE_COUNT || nodes == nil ||
		root_index < 0 || u64(root_index) >= u64(node_count) || k < 1 || u64(k) > u64(node_count) {
		return -1
	}
	remaining := k
	result := kth_visit(nodes, node_count, root_index, &remaining)
	if result < 0 do return -1
	return result
}
