module max_depth

const max_node_count = 1023

fn max_depth_max(left i64, right i64) i64 {
	if left > right { return left }
	return right
}

fn max_depth_visit(nodes &i64, node_count usize, node i64) i64 {
	if node == -1 { return 0 }
	if node < 0 || u64(node) >= u64(node_count) { return -1 }
	index := usize(node)
	unsafe {
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		left_depth := max_depth_visit(nodes, node_count, left)
		if left_depth < 0 { return -1 }
		right_depth := max_depth_visit(nodes, node_count, right)
		if right_depth < 0 { return -1 }
		return 1 + max_depth_max(left_depth, right_depth)
	}
}

@[export: 'max_depth']
pub fn max_depth(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(0) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	return max_depth_visit(nodes, node_count, root_index)
}
