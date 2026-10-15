module kth_smallest_bst

const max_node_count = 1023
const max_value = 10000
const invalid_tree_result = i64(-9223372036854775807 - 1)

fn kth_visit(nodes &i64, node_count usize, node i64, mut remaining &i64) i64 {
	if node == -1 { return -1 }
	if node < 0 || u64(node) >= u64(node_count) { return invalid_tree_result }
	index := usize(node)
	unsafe {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if value < 0 || value > max_value || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) ||
			(right >= 0 && u64(right) >= u64(node_count)) { return invalid_tree_result }
		left_result := kth_visit(nodes, node_count, left, mut remaining)
		if left_result >= 0 || left_result == invalid_tree_result { return left_result }
		remaining[0]--
		if remaining[0] == 0 { return value }
		return kth_visit(nodes, node_count, right, mut remaining)
	}
}

@[export: 'kth_smallest_bst']
pub fn kth_smallest_bst(nodes &i64, node_count usize, root_index i64, k i64) i64 {
	if node_count == 0 || node_count > max_node_count || root_index < 0 ||
		u64(root_index) >= u64(node_count) || k < 1 || u64(k) > u64(node_count) { return -1 }
	mut remaining := k
	result := kth_visit(nodes, node_count, root_index, mut remaining)
	if result < 0 { return -1 }
	return result
}
