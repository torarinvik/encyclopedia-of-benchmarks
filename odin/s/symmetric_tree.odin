package symmetric_tree

import "core:c"

MAX_NODE_COUNT :: 1023

symmetric_tree_mirror :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, left, right: i64) -> i64 {
	if left == -1 || right == -1 {
		if left == right do return 1
		return 0
	}
	if left < 0 || right < 0 || u64(left) >= u64(node_count) || u64(right) >= u64(node_count) do return -1
	left_node := c.size_t(left)
	right_node := c.size_t(right)
	if nodes[3 * left_node] != nodes[3 * right_node] do return 0
	left_left, left_right := nodes[3 * left_node + 1], nodes[3 * left_node + 2]
	right_left, right_right := nodes[3 * right_node + 1], nodes[3 * right_node + 2]
	if left_left < -1 || (left_left >= 0 && u64(left_left) >= u64(node_count)) ||
		left_right < -1 || (left_right >= 0 && u64(left_right) >= u64(node_count)) ||
		right_left < -1 || (right_left >= 0 && u64(right_left) >= u64(node_count)) ||
		right_right < -1 || (right_right >= 0 && u64(right_right) >= u64(node_count)) {
		return -1
	}
	outer := symmetric_tree_mirror(nodes, node_count, left_left, right_right)
	if outer != 1 do return outer
	return symmetric_tree_mirror(nodes, node_count, left_right, right_left)
}

@(export)
symmetric_tree :: proc "c" (nodes: [^]i64, node_count: c.size_t, root_index: i64) -> i64 {
	if node_count > MAX_NODE_COUNT do return -1
	if node_count == 0 {
		if root_index == -1 do return 1
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	root := c.size_t(root_index)
	left, right := nodes[3 * root + 1], nodes[3 * root + 2]
	if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		right < -1 || (right >= 0 && u64(right) >= u64(node_count)) {
		return -1
	}
	return symmetric_tree_mirror(nodes, node_count, left, right)
}
