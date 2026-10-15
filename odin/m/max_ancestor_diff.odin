package max_ancestor_diff

import "core:c"

MAX_NODE_COUNT :: 1023

visit :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, node: i64,
		path_min, path_max: i64) -> i64 {
	if node == -1 do return 0
	if node < 0 || u64(node) >= u64(node_count) do return -1
	index := c.size_t(node)
	value := nodes[3 * index]
	if value < -100_000 || value > 100_000 do return -1
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		right < -1 || (right >= 0 && u64(right) >= u64(node_count)) {
		return -1
	}
	best := max(path_min-value, value-path_min)
	best = max(best, max(path_max-value, value-path_max))
	low, high := min(path_min, value), max(path_max, value)
	left_best := visit(nodes, node_count, left, low, high)
	if left_best < 0 do return -1
	right_best := visit(nodes, node_count, right, low, high)
	if right_best < 0 do return -1
	return max(best, max(left_best, right_best))
}

@(export)
max_ancestor_diff :: proc "contextless" (nodes: [^]i64,
		node_count: c.size_t, root_index: i64) -> i64 {
	if node_count == 0 || node_count > MAX_NODE_COUNT || nodes == nil || root_index < 0 ||
		u64(root_index) >= u64(node_count) {
		return -1
	}
	root_value := nodes[3 * c.size_t(root_index)]
	if root_value < -100_000 || root_value > 100_000 do return -1
	return visit(nodes, node_count, root_index, root_value, root_value)
}
