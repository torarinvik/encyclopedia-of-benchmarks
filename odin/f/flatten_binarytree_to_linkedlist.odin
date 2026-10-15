package flatten_binarytree_to_linkedlist

import "core:c"

MAX_NODE_COUNT :: 1023
MAX_TREE_HEIGHT :: 512

validate :: proc "c" (nodes: [^]i64, count: int, index: i64, depth: int,
		visited: [^]bool, seen: ^int) -> bool {
	if index == -1 do return true
	if index < 0 || index >= i64(count) || depth > MAX_TREE_HEIGHT do return false
	node := int(index)
	if visited[node] do return false
	visited[node] = true
	seen^ += 1
	off := 3 * node
	value, left, right := nodes[off], nodes[off + 1], nodes[off + 2]
	if value < -2_147_483_648 || value > 2_147_483_647 || left < -1 || right < -1 ||
		left >= i64(count) || right >= i64(count) { return false }
	return validate(nodes, count, left, depth + 1, visited, seen) &&
		validate(nodes, count, right, depth + 1, visited, seen)
}

flatten :: proc "c" (nodes: [^]i64, index: i64) {
	if index == -1 do return
	off := 3 * int(index)
	left := nodes[off + 1]
	flatten(nodes, left)
	original_right := nodes[off + 2]
	nodes[off + 2] = left
	nodes[off + 1] = -1
	tail := index
	for nodes[3 * int(tail) + 2] != -1 { tail = nodes[3 * int(tail) + 2] }
	nodes[3 * int(tail) + 2] = original_right
	flatten(nodes, original_right)
}

store_i64 :: proc "c" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[offset + b] = u8((bits >> u64(8 * b)) & 255) }
}

@(export)
flatten_binarytree_to_linkedlist :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * MAX_NODE_COUNT do return -1
	count := int((length - 1) / 3)
	root := values[0]
	if count == 0 { return if root == -1 do 0 else -1 }
	if root < 0 || root >= i64(count) do return -1
	nodes: [3 * MAX_NODE_COUNT]i64
	for i := 0; i < 3 * count; i += 1 { nodes[i] = values[i + 1] }
	visited := [MAX_NODE_COUNT]bool{}
	seen := 0
	if !validate(&nodes[0], count, root, 1, &visited[0], &seen) || seen != count do return -1
	if capacity < c.size_t(24 * count) do return -2
	flatten(&nodes[0], root)
	for i := 0; i < count; i += 1 {
		store_i64(output, 24 * i, nodes[3 * i])
		store_i64(output, 24 * i + 8, nodes[3 * i + 1])
		store_i64(output, 24 * i + 16, nodes[3 * i + 2])
	}
	return i64(count)
}
