package binary_tree_inorder_traversal

import "core:c"

MAX_NODE_COUNT :: 100

inorder_visit :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, node: i64,
		output: [^]i64, capacity: c.size_t, used: ^c.size_t) -> bool {
	if node == -1 do return true
	if node < 0 || u64(node) >= u64(node_count) do return false
	index := c.size_t(node)
	value := nodes[3 * index]
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if value < -100 || value > 100 || left < -1 || right < -1 ||
		(left >= 0 && u64(left) >= u64(node_count)) ||
		(right >= 0 && u64(right) >= u64(node_count)) { return false }
	if !inorder_visit(nodes, node_count, left, output, capacity, used) do return false
	if used^ >= capacity do return false
	output[used^] = value
	used^ += 1
	return inorder_visit(nodes, node_count, right, output, capacity, used)
}

@(export)
binary_tree_inorder_traversal :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		root_index: i64, output: [^]i64, output_capacity: c.size_t) -> i64 {
	if node_count > MAX_NODE_COUNT || output_capacity < node_count do return -1
	if node_count == 0 {
		if root_index == -1 do return 0
		return -1
	}
	if nodes == nil || output == nil || root_index < 0 || u64(root_index) >= u64(node_count) {
		return -1
	}
	used := c.size_t(0)
	if !inorder_visit(nodes, node_count, root_index, output, output_capacity, &used) do return -1
	if used != node_count do return -1
	return i64(used)
}
