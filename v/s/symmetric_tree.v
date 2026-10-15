module symmetric_tree

const max_node_count = 1023

fn symmetric_tree_mirror(nodes &i64, node_count usize, left i64, right i64) i64 {
	if left == -1 || right == -1 { return if left == right { 1 } else { 0 } }
	if left < 0 || right < 0 || u64(left) >= u64(node_count) || u64(right) >= u64(node_count) { return -1 }
	left_node := usize(left)
	right_node := usize(right)
	unsafe {
		if nodes[3 * left_node] != nodes[3 * right_node] { return 0 }
		left_left := nodes[3 * left_node + 1]
		left_right := nodes[3 * left_node + 2]
		right_left := nodes[3 * right_node + 1]
		right_right := nodes[3 * right_node + 2]
		if left_left < -1 || (left_left >= 0 && u64(left_left) >= u64(node_count)) ||
			left_right < -1 || (left_right >= 0 && u64(left_right) >= u64(node_count)) ||
			right_left < -1 || (right_left >= 0 && u64(right_left) >= u64(node_count)) ||
			right_right < -1 || (right_right >= 0 && u64(right_right) >= u64(node_count)) { return -1 }
		outer := symmetric_tree_mirror(nodes, node_count, left_left, right_right)
		if outer != 1 { return outer }
		return symmetric_tree_mirror(nodes, node_count, left_right, right_left)
	}
}

@[export: 'symmetric_tree']
pub fn symmetric_tree(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { 1 } else { -1 } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	root := usize(root_index)
	unsafe {
		left := nodes[3 * root + 1]
		right := nodes[3 * root + 2]
		if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		return symmetric_tree_mirror(nodes, node_count, left, right)
	}
}
