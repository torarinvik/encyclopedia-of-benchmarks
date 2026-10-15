package bst_from_preorder

import "core:c"

valid_preorder :: proc "contextless" (values: [^]i64, start, end: c.size_t, lower, upper: i64) -> bool {
	if start == end do return true
	root := values[start]
	if root <= lower || root >= upper do return false
	split := start + 1
	for split < end && values[split] < root { split += 1 }
	return valid_preorder(values, start + 1, split, lower, root) &&
		valid_preorder(values, split, end, root, upper)
}

emit_preorder_tree :: proc "contextless" (values: [^]i64, start, end: c.size_t,
		output: [^]u8, position: c.size_t) -> c.size_t {
	if start == end { output[position] = 0; return position + 1 }
	root := values[start]
	split := start + 1
	for split < end && values[split] < root { split += 1 }
	output[position] = 1
	encoded := root
	if encoded < 0 { encoded += 4294967296 }
	output[position + 1] = u8(encoded % 256)
	output[position + 2] = u8((encoded / 256) % 256)
	output[position + 3] = u8((encoded / 65536) % 256)
	output[position + 4] = u8(encoded / 16777216)
	next_position := emit_preorder_tree(values, start + 1, split, output, position + 5)
	return emit_preorder_tree(values, split, end, output, next_position)
}

// Validate and serialize a strict BST reconstructed from preorder values.
@(export)
bst_from_preorder :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > 15 do return -1
	for index: c.size_t = 0; index < length; index += 1 {
		if values[index] < -2147483648 || values[index] > 2147483647 do return -1
	}
	if !valid_preorder(values, 0, length, -2147483649, 2147483648) do return -1
	required := 6 * length + 1
	if output_capacity < required || output == nil do return -2
	emit_preorder_tree(values, 0, length, output, 0)
	return i64(length)
}
