module bst_from_preorder

fn valid_preorder(values &i64, start usize, end usize, lower i64, upper i64) bool {
	if start == end { return true }
	root := unsafe { values[start] }
	if root <= lower || root >= upper { return false }
	mut split := start + 1
	for split < end && unsafe { values[split] } < root { split++ }
	return valid_preorder(values, start + 1, split, lower, root) &&
		valid_preorder(values, split, end, root, upper)
}

fn emit_preorder_tree(values &i64, start usize, end usize, output &u8, position usize) usize {
	if start == end { unsafe { output[position] = 0 }; return position + 1 }
	root := unsafe { values[start] }
	mut split := start + 1
	for split < end && unsafe { values[split] } < root { split++ }
	unsafe { output[position] = 1 }
	encoded := if root < 0 { root + 4294967296 } else { root }
	unsafe {
		output[position + 1] = u8(encoded % 256)
		output[position + 2] = u8((encoded / 256) % 256)
		output[position + 3] = u8((encoded / 65536) % 256)
		output[position + 4] = u8(encoded / 16777216)
	}
	next_position := emit_preorder_tree(values, start + 1, split, output, position + 5)
	return emit_preorder_tree(values, split, end, output, next_position)
}

// Validate and serialize a strict BST reconstructed from preorder values.
@[export: 'bst_from_preorder']
pub fn bst_from_preorder(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > 15 { return -1 }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	if !valid_preorder(values, 0, length, -2147483649, 2147483648) { return -1 }
	required := 6 * length + 1
	if output_capacity < required { return -2 }
	emit_preorder_tree(values, 0, length, output, 0)
	return i64(length)
}
