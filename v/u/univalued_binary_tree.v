module univalued_binary_tree

const max_node_count = 1023

fn univalued_visit(nodes &i64, node_count usize, node i64) i64 {
	if node == -1 { return 1 }
	if node < 0 || u64(node) >= u64(node_count) { return -1 }
	index := usize(node)
	unsafe {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		if (left >= 0 && nodes[3 * usize(left)] != value) ||
			(right >= 0 && nodes[3 * usize(right)] != value) { return 0 }
		left_result := univalued_visit(nodes, node_count, left)
		if left_result <= 0 { return left_result }
		return univalued_visit(nodes, node_count, right)
	}
}

@[export: 'univalued_binary_tree']
pub fn univalued_binary_tree(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(1) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	return univalued_visit(nodes, node_count, root_index)
}
