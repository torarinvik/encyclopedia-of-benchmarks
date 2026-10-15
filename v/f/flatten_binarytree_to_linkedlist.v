module flatten_binarytree_to_linkedlist

const max_node_count = 1023
const max_tree_height = 512

fn validate(nodes &i64, count usize, index i64, depth usize, mut visited []bool, mut seen usize) bool {
	if index == -1 { return true }
	if index < 0 || u64(index) >= u64(count) || depth > max_tree_height { return false }
	node := usize(index)
	if visited[node] { return false }
	visited[node] = true
	seen++
	unsafe {
		off := 3 * node
		value, left, right := nodes[off], nodes[off + 1], nodes[off + 2]
		if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(count)) || (right >= 0 && u64(right) >= u64(count)) { return false }
		return validate(nodes, count, left, depth + 1, mut visited, mut seen) &&
			validate(nodes, count, right, depth + 1, mut visited, mut seen)
	}
}

fn flatten(mut nodes []i64, index i64) {
	if index == -1 { return }
	off := 3 * usize(index)
	left := nodes[off + 1]
	flatten(mut nodes, left)
	original_right := nodes[off + 2]
	nodes[off + 2] = left
	nodes[off + 1] = -1
	tail := index
	for nodes[3 * usize(tail) + 2] != -1 { tail = nodes[3 * usize(tail) + 2] }
	nodes[3 * usize(tail) + 2] = original_right
	flatten(mut nodes, original_right)
}

fn store_i64(mut output []u8, offset usize, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { output[offset + b] = u8((bits >> u64(8 * b)) & 255) }
}

@[export: 'flatten_binarytree_to_linkedlist']
pub fn flatten_binarytree_to_linkedlist(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * max_node_count { return -1 }
	count := (length - 1) / 3
	root := unsafe { values[0] }
	if count == 0 { return if root == -1 { 0 } else { -1 } }
	if root < 0 || u64(root) >= u64(count) { return -1 }
	mut nodes := []i64{len: 3 * count, init: 0}
	unsafe { for i in 0 .. 3 * count { nodes[i] = values[i + 1] } }
	mut visited := []bool{len: count, init: false}
	mut seen := usize(0)
	if !validate(&nodes[0], count, root, 1, mut visited, mut seen) || seen != count { return -1 }
	if capacity < 24 * count { return -2 }
	flatten(mut nodes, root)
	unsafe {
		for i in 0 .. count {
			store_i64(mut output[..], 24 * i, nodes[3 * i])
			store_i64(mut output[..], 24 * i + 8, nodes[3 * i + 1])
			store_i64(mut output[..], 24 * i + 16, nodes[3 * i + 2])
		}
	}
	return i64(count)
}
