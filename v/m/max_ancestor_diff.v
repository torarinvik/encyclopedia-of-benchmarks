module max_ancestor_diff

const max_node_count = 1023

fn max_ancestor_diff_min(left i64, right i64) i64 {
	if left < right { return left }
	return right
}

fn max_ancestor_diff_max(left i64, right i64) i64 {
	if left > right { return left }
	return right
}

fn max_ancestor_diff_visit(nodes &i64, node_count usize, node i64, path_min i64, path_max i64) i64 {
	if node == -1 { return 0 }
	if node < 0 || u64(node) >= u64(node_count) { return -1 }
	index := usize(node)
	unsafe {
		value := nodes[3 * index]
		if value < -100_000 || value > 100_000 { return -1 }
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		mut best := max_ancestor_diff_max(path_min-value, value-path_min)
		best = max_ancestor_diff_max(best, max_ancestor_diff_max(path_max-value, value-path_max))
		low := max_ancestor_diff_min(path_min, value)
		high := max_ancestor_diff_max(path_max, value)
		left_best := max_ancestor_diff_visit(nodes, node_count, left, low, high)
		if left_best < 0 { return -1 }
		right_best := max_ancestor_diff_visit(nodes, node_count, right, low, high)
		if right_best < 0 { return -1 }
		return max_ancestor_diff_max(best, max_ancestor_diff_max(left_best, right_best))
	}
}

@[export: 'max_ancestor_diff']
pub fn max_ancestor_diff(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count == 0 || node_count > max_node_count || root_index < 0 ||
		u64(root_index) >= u64(node_count) { return -1 }
	root := usize(root_index)
	unsafe {
		root_value := nodes[3 * root]
		if root_value < -100_000 || root_value > 100_000 { return -1 }
		return max_ancestor_diff_visit(nodes, node_count, root_index, root_value, root_value)
	}
}
