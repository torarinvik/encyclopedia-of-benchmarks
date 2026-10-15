package invert_binary_tree

import "core:c"

MAX_NODE_COUNT :: 1023
MAX_TREE_HEIGHT :: 512

validate_subtree :: proc "c" (values: [^]i64, node_count: int, index: i64, depth: int,
		visited: [^]bool) -> bool {
	if index == -1 do return true
	if index < 0 || index >= i64(node_count) || depth > MAX_TREE_HEIGHT do return false
	node := int(index)
	if visited[node] do return false
	visited[node] = true
	offset := 1 + 3 * node
	value, left, right := values[offset], values[offset + 1], values[offset + 2]
	if value < -2_147_483_648 || value > 2_147_483_647 || left < -1 || right < -1 ||
		(left >= 0 && left >= i64(node_count)) || (right >= 0 && right >= i64(node_count)) {
		return false
	}
	return validate_subtree(values, node_count, left, depth + 1, visited) &&
		validate_subtree(values, node_count, right, depth + 1, visited)
}

store_i64_little_endian :: proc "c" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
	}
}

emit_mirrored_subtree :: proc "c" (values: [^]i64, index: i64, output: [^]u8) {
	if index == -1 do return
	input_offset := 1 + 3 * int(index)
	output_offset := 24 * int(index)
	left, right := values[input_offset + 1], values[input_offset + 2]
	store_i64_little_endian(output, output_offset, values[input_offset])
	store_i64_little_endian(output, output_offset + 8, right)
	store_i64_little_endian(output, output_offset + 16, left)
	emit_mirrored_subtree(values, right, output)
	emit_mirrored_subtree(values, left, output)
}

// Return a mirrored copy of a valid indexed binary tree in little-endian triplets.
@(export)
invert_binary_tree :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * MAX_NODE_COUNT do return -1
	node_count := int((length - 1) / 3)
	root := values[0]
	if node_count == 0 {
		if root == -1 do return 0
		return -1
	}
	if root < 0 || root >= i64(node_count) do return -1
	visited := [MAX_NODE_COUNT]bool{}
	if !validate_subtree(values, node_count, root, 1, &visited[0]) do return -1
	for index := 0; index < node_count; index += 1 {
		if !visited[index] do return -1
	}
	required := 24 * node_count
	if output == nil || output_capacity < c.size_t(required) do return -2
	emit_mirrored_subtree(values, root, output)
	return i64(node_count)
}
