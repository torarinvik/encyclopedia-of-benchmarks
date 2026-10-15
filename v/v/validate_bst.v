module validate_bst

@[export: 'validate_bst']
pub fn validate_bst(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > 1023 { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(1) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	return validate_subtree(nodes, node_count, root_index, false, 0, false, 0)
}

fn validate_subtree(nodes &i64, node_count usize, node i64,
	has_lower bool, lower i64, has_upper bool, upper i64) i64 {
	if node == -1 { return 1 }
	if node < 0 || u64(node) >= u64(node_count) { return -1 }
	index := usize(node)
	unsafe {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if value < -2147483648 || value > 2147483647 ||
			left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		if (has_lower && value <= lower) || (has_upper && value >= upper) { return 0 }
		left_result := validate_subtree(nodes, node_count, left, has_lower, lower, true, value)
		if left_result <= 0 { return left_result }
		return validate_subtree(nodes, node_count, right, true, value, has_upper, upper)
	}
}
