module balanced_binary_tree

const max_node_count = 1023

fn balanced_tree_max(left i64, right i64) i64 {
	if left > right { return left }
	return right
}

fn tree_height(nodes &i64, node_count usize, node i64) i64 {
	if node == -1 { return 0 }
	if node < 0 || u64(node) >= u64(node_count) { return -1 }
	index := usize(node)
	unsafe {
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		left_height := tree_height(nodes, node_count, left)
		if left_height < 0 { return -1 }
		right_height := tree_height(nodes, node_count, right)
		if right_height < 0 { return -1 }
		return 1 + balanced_tree_max(left_height, right_height)
	}
}

fn balanced_visit(nodes &i64, node_count usize, node i64) i64 {
	if node == -1 { return 1 }
	if node < 0 || u64(node) >= u64(node_count) { return -1 }
	index := usize(node)
	unsafe {
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		left_height := tree_height(nodes, node_count, left)
		if left_height < 0 { return -1 }
		right_height := tree_height(nodes, node_count, right)
		if right_height < 0 { return -1 }
		difference := left_height - right_height
		if difference < 0 { difference = -difference }
		if difference > 1 { return 0 }
		left_balanced := balanced_visit(nodes, node_count, left)
		if left_balanced <= 0 { return left_balanced }
		return balanced_visit(nodes, node_count, right)
	}
}

@[export: 'balanced_binary_tree']
pub fn balanced_binary_tree(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(1) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	return balanced_visit(nodes, node_count, root_index)
}
