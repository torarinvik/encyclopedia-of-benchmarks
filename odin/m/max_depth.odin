package max_depth

import "core:c"

MAX_NODE_COUNT :: 1023

tree_depth :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, node: i64) -> i64 {
	if node == -1 do return 0
	if node < 0 || u64(node) >= u64(node_count) do return -1
	index := c.size_t(node)
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		right < -1 || (right >= 0 && u64(right) >= u64(node_count)) {
		return -1
	}
	left_depth := tree_depth(nodes, node_count, left)
	if left_depth < 0 do return -1
	right_depth := tree_depth(nodes, node_count, right)
	if right_depth < 0 do return -1
	return 1 + max(left_depth, right_depth)
}

@(export)
max_depth :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, root_index: i64) -> i64 {
	if node_count > MAX_NODE_COUNT do return -1
	if node_count == 0 {
		if root_index == -1 do return 0
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) {
		return -1
	}
	return tree_depth(nodes, node_count, root_index)
}
