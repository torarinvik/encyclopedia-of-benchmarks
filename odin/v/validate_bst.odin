package validate_bst

import "core:c"

MAX_NODE_COUNT :: 1023
VALUE_MIN :: i64(-2147483648)
VALUE_MAX :: i64(2147483647)

validate_subtree :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, node: i64,
		has_lower: bool, lower: i64, has_upper: bool, upper: i64) -> i64 {
	if node == -1 do return 1
	if node < 0 || u64(node) >= u64(node_count) do return -1
	index := c.size_t(node)
	value := nodes[3 * index]
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if value < VALUE_MIN || value > VALUE_MAX ||
		left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		right < -1 || (right >= 0 && u64(right) >= u64(node_count)) {
		return -1
	}
	if (has_lower && value <= lower) || (has_upper && value >= upper) do return 0
	left_result := validate_subtree(nodes, node_count, left, has_lower, lower, true, value)
	if left_result <= 0 do return left_result
	return validate_subtree(nodes, node_count, right, true, value, has_upper, upper)
}

@(export)
validate_bst :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, root_index: i64) -> i64 {
	if node_count > MAX_NODE_COUNT do return -1
	if node_count == 0 {
		if root_index == -1 do return 1
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	return validate_subtree(nodes, node_count, root_index, false, 0, false, 0)
}
