module diameter_of_binary_tree

const max_node_count = 1023
const error_sentinel = i64(-2000000000)

struct DiameterState {
	mut:
	seen [max_node_count]bool
	visited int
}

fn height_and_check(nodes &i64, node_count int, node i64, mut state DiameterState) i64 {
	if node == -1 { return 0 }
	if node < 0 || u64(node) >= u64(node_count) { return error_sentinel }
	index := int(node)
	if state.seen[index] { return error_sentinel }
	state.seen[index] = true
	state.visited++
	left := unsafe { nodes[3 * index + 1] }
	right := unsafe { nodes[3 * index + 2] }
	if left < -1 || right < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		(right >= 0 && u64(right) >= u64(node_count)) { return error_sentinel }
	left_height := height_and_check(nodes, node_count, left, mut state)
	if left_height == error_sentinel { return error_sentinel }
	right_height := height_and_check(nodes, node_count, right, mut state)
	if right_height == error_sentinel { return error_sentinel }
	return 1 + max(left_height, right_height)
}

@[export: 'diameter_of_binary_tree']
pub fn diameter_of_binary_tree(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count < 1 || node_count > max_node_count || root_index < 0 ||
		u64(root_index) >= u64(node_count) { return -1 }
	root := int(root_index)
	left := unsafe { nodes[3 * root + 1] }
	right := unsafe { nodes[3 * root + 2] }
	if left < -1 || right < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
		(right >= 0 && u64(right) >= u64(node_count)) { return -1 }
	mut state := DiameterState{visited: 1}
	state.seen[root] = true
	left_height := height_and_check(nodes, int(node_count), left, mut state)
	if left_height == error_sentinel { return -1 }
	right_height := height_and_check(nodes, int(node_count), right, mut state)
	if right_height == error_sentinel || state.visited != int(node_count) { return -1 }
	return left_height + right_height + 1
}
