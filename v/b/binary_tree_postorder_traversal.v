module binary_tree_postorder_traversal

const max_node_count = 100

fn postorder_visit(nodes &i64, node_count usize, node i64,
	mut output &i64, capacity usize, mut used &usize) bool {
	if node == -1 { return true }
	if node < 0 || u64(node) >= u64(node_count) { return false }
	index := usize(node)
	unsafe {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) ||
			(right >= 0 && u64(right) >= u64(node_count)) { return false }
		if !postorder_visit(nodes, node_count, left, mut output, capacity, mut used) { return false }
		if !postorder_visit(nodes, node_count, right, mut output, capacity, mut used) { return false }
		if used[0] >= capacity { return false }
		output[used[0]] = value
		used[0]++
		return true
	}
}

@[export: 'binary_tree_postorder_traversal']
pub fn binary_tree_postorder_traversal(nodes &i64, node_count usize, root_index i64,
	mut output &i64, output_capacity usize) i64 {
	if node_count > max_node_count || output_capacity < node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(0) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	mut used := usize(0)
	if !postorder_visit(nodes, node_count, root_index, mut output, output_capacity, mut used) ||
		used != node_count { return -1 }
	return i64(used)
}
