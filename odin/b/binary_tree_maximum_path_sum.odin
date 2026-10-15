package binary_tree_maximum_path_sum

import "core:c"

MAX_NODE_COUNT :: 1023
ERROR_SENTINEL :: i64(-2_000_000_000)

maximum_gain :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		node: i64, best_path: ^i64) -> i64 {
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
	left_gain := maximum_gain(nodes, node_count, left, best_path)
	if left_gain == ERROR_SENTINEL do return ERROR_SENTINEL
	right_gain := maximum_gain(nodes, node_count, right, best_path)
	if right_gain == ERROR_SENTINEL do return ERROR_SENTINEL
	positive_left := max(left_gain, 0)
	positive_right := max(right_gain, 0)
	through_node := value + positive_left + positive_right
	if through_node > best_path^ do best_path^ = through_node
	return value + max(positive_left, positive_right)
}

@(export)
binary_tree_maximum_path_sum :: proc "contextless" (nodes: [^]i64,
		node_count: c.size_t, root_index: i64) -> i64 {
	if node_count == 0 || node_count > MAX_NODE_COUNT || nodes == nil ||
		root_index < 0 || u64(root_index) >= u64(node_count) {
		return -1
	}
	best_path := i64(-2_147_483_648)
	gain := maximum_gain(nodes, node_count, root_index, &best_path)
	if gain == ERROR_SENTINEL do return -1
	return best_path
}
