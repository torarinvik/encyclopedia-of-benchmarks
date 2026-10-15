module check_if_binary_tree_balanced

const max_node_count = 1023

fn balanced_height(nodes &i64, count usize, node i64, balanced &bool) i64 {
	if node == -1 || !balanced { return 0 }
	if node < 0 || u64(node) >= u64(count) { return -1 }
	index := usize(node)
	unsafe {
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if left < -1 || (left >= 0 && u64(left) >= u64(count)) ||
			right < -1 || (right >= 0 && u64(right) >= u64(count)) { return -1 }
		left_height := balanced_height(nodes, count, left, balanced)
		if left_height < 0 { return -1 }
		right_height := balanced_height(nodes, count, right, balanced)
		if right_height < 0 { return -1 }
		difference := left_height - right_height
		if difference < 0 { difference = -difference }
		if difference > 1 { *balanced = false }
		return 1 + if left_height > right_height { left_height } else { right_height }
	}
}

@[export: 'check_if_binary_tree_balanced']
pub fn check_if_binary_tree_balanced(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(1) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	mut balanced := true
	unsafe {
		height := balanced_height(nodes, node_count, root_index, &balanced)
		if height < 0 { return -1 }
	}
	return if balanced { 1 } else { 0 }
}
