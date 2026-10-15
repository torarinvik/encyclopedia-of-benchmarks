package check_if_binary_tree_balanced

import "core:c"

MAX_NODE_COUNT :: 1023

balanced_height :: proc "contextless" (nodes: [^]i64, count: c.size_t,
		node: i64, balanced: ^bool) -> i64 {
	if node == -1 || !balanced^ do return 0
	if node < 0 || u64(node) >= u64(count) do return -1
	index := c.size_t(node)
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if left < -1 || (left >= 0 && u64(left) >= u64(count)) ||
		right < -1 || (right >= 0 && u64(right) >= u64(count)) {
		return -1
	}
	left_height := balanced_height(nodes, count, left, balanced)
	if left_height < 0 do return -1
	right_height := balanced_height(nodes, count, right, balanced)
	if right_height < 0 do return -1
	difference := left_height - right_height
	if difference < 0 do difference = -difference
	if difference > 1 do balanced^ = false
	return 1 + max(left_height, right_height)
}

@(export)
check_if_binary_tree_balanced :: proc "contextless" (nodes: [^]i64,
		node_count: c.size_t, root_index: i64) -> i64 {
	if node_count > MAX_NODE_COUNT do return -1
	if node_count == 0 {
		if root_index == -1 do return 1
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	balanced := true
	height := balanced_height(nodes, node_count, root_index, &balanced)
	if height < 0 do return -1
	if balanced do return 1
	return 0
}
