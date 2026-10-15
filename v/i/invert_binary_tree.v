module invert_binary_tree

const max_node_count = 1023
const max_tree_height = 512

fn validate_subtree(values &i64, node_count usize, index i64, depth usize, mut visited []bool) bool {
	if index == -1 { return true }
	if index < 0 || u64(index) >= u64(node_count) || depth > max_tree_height { return false }
	node := usize(index)
	if visited[node] { return false }
	visited[node] = true
	unsafe {
		offset := 1 + 3 * node
		value := values[offset]
		left := values[offset + 1]
		right := values[offset + 2]
		if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) ||
			(right >= 0 && u64(right) >= u64(node_count)) { return false }
		return validate_subtree(values, node_count, left, depth + 1, mut visited) &&
			validate_subtree(values, node_count, right, depth + 1, mut visited)
	}
}

fn store_i64_little_endian(output &u8, offset usize, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & u64(255))
		}
	}
}

fn emit_mirrored_subtree(values &i64, index i64, output &u8) {
	if index == -1 { return }
	unsafe {
		input_offset := 1 + 3 * usize(index)
		output_offset := 24 * usize(index)
		left := values[input_offset + 1]
		right := values[input_offset + 2]
		store_i64_little_endian(output, output_offset, values[input_offset])
		store_i64_little_endian(output, output_offset + 8, right)
		store_i64_little_endian(output, output_offset + 16, left)
		emit_mirrored_subtree(values, right, output)
		emit_mirrored_subtree(values, left, output)
	}
}

// Return a mirrored copy of a valid indexed binary tree in little-endian triplets.
@[export: 'invert_binary_tree']
pub fn invert_binary_tree(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * max_node_count { return -1 }
	node_count := (length - 1) / 3
	root := unsafe { values[0] }
	if node_count == 0 { return if root == -1 { 0 } else { -1 } }
	if root < 0 || u64(root) >= u64(node_count) { return -1 }
	mut visited := []bool{len: max_node_count, init: false}
	if !validate_subtree(values, node_count, root, 1, mut visited) { return -1 }
	for index in 0 .. node_count {
		if !visited[index] { return -1 }
	}
	required := 24 * node_count
	if output_capacity < required { return -2 }
	emit_mirrored_subtree(values, root, output)
	return i64(node_count)
}
