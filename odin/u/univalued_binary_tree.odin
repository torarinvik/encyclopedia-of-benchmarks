package univalued_binary_tree

import "core:c"

MAX_NODE_COUNT :: 1023

is_univalued :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, node: i64) -> i64 {
	if node == -1 do return 1
	if node < 0 || u64(node) >= u64(node_count) do return -1
	index := c.size_t(node)
	value := nodes[3 * index]
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		right < -1 || (right >= 0 && u64(right) >= u64(node_count)) {
		return -1
	}
	if (left >= 0 && nodes[3 * c.size_t(left)] != value) ||
		(right >= 0 && nodes[3 * c.size_t(right)] != value) {
		return 0
	}
	left_result := is_univalued(nodes, node_count, left)
	if left_result <= 0 do return left_result
	return is_univalued(nodes, node_count, right)
}

@(export)
univalued_binary_tree :: proc "contextless" (nodes: [^]i64,
		node_count: c.size_t, root_index: i64) -> i64 {
	if node_count > MAX_NODE_COUNT do return -1
	if node_count == 0 {
		if root_index == -1 do return 1
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) {
		return -1
	}
	return is_univalued(nodes, node_count, root_index)
}
