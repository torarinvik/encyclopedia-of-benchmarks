package red_black_tree_insert_search

import "core:c"

MAX_OPERATIONS :: 128
INVALID_RESULT :: i64(-1)
CAPACITY_RESULT :: i64(-2)

Node :: struct { key: i64, left: int, right: int, red: bool }

is_red :: proc "contextless" (tree: [^]Node, node: int) -> bool { return node != 0 && tree[node].red }
flip_colors :: proc "contextless" (tree: [^]Node, node: int) {
	tree[node].red = !tree[node].red
	left, right := tree[node].left, tree[node].right
	tree[left].red = !tree[left].red
	tree[right].red = !tree[right].red
}
rotate_left :: proc "contextless" (tree: [^]Node, node: int) -> int {
	pivot := tree[node].right
	tree[node].right = tree[pivot].left
	tree[pivot].left = node
	tree[pivot].red = tree[node].red
	tree[node].red = true
	return pivot
}
rotate_right :: proc "contextless" (tree: [^]Node, node: int) -> int {
	pivot := tree[node].left
	tree[node].left = tree[pivot].right
	tree[pivot].right = node
	tree[pivot].red = tree[node].red
	tree[node].red = true
	return pivot
}
insert_node :: proc "contextless" (tree: [^]Node, node: int, key: i64, next: ^int) -> int {
	if node == 0 {
		created := next^
		next^ += 1
		tree[created] = Node{key = key, left = 0, right = 0, red = true}
		return created
	}
	if is_red(tree, tree[node].left) && is_red(tree, tree[node].right) { flip_colors(tree, node) }
	if key == tree[node].key { tree[node].key = key }
	else if key < tree[node].key { tree[node].left = insert_node(tree, tree[node].left, key, next) }
	else { tree[node].right = insert_node(tree, tree[node].right, key, next) }
	if is_red(tree, tree[node].right) && !is_red(tree, tree[node].left) { return rotate_left(tree, node) }
	if is_red(tree, tree[node].left) && is_red(tree, tree[tree[node].left].left) { return rotate_right(tree, node) }
	return node
}
find_node :: proc "contextless" (tree: [^]Node, start: int, key: i64) -> int {
	node := start
	for node != 0 {
		if key < tree[node].key { node = tree[node].left }
		else if key > tree[node].key { node = tree[node].right }
		else { return node }
	}
	return 0
}
insertion_sort :: proc "contextless" (values: [^]i64, count: int) {
	for index := 1; index < count; index += 1 {
		value := values[index]
		position := index
		for position > 0 && values[position - 1] > value { values[position] = values[position - 1]; position -= 1 }
		values[position] = value
	}
}
write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
red_black_tree_insert_search :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return INVALID_RESULT
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return INVALID_RESULT
	operation_count := int(input[0])
	if length != c.size_t(1 + 2 * operation_count) do return INVALID_RESULT
	for op := 0; op < operation_count; op += 1 {
		opcode, key := input[1 + 2 * op], input[2 + 2 * op]
		if (opcode != 0 && opcode != 1) || key < -2_147_483_648 || key > 2_147_483_647 do return INVALID_RESULT
	}
	tree: [MAX_OPERATIONS + 1]Node
	for index := 0; index <= MAX_OPERATIONS; index += 1 { tree[index] = Node{} }
	keys: [MAX_OPERATIONS]i64
	search_results: [MAX_OPERATIONS]i64
	root, next, key_count, search_count := 0, 1, 0, 0
	for op := 0; op < operation_count; op += 1 {
		opcode, key := input[1 + 2 * op], input[2 + 2 * op]
		if opcode == 0 {
			if find_node(&tree[0], root, key) != 0 do return INVALID_RESULT
			root = insert_node(&tree[0], root, key, &next)
			tree[root].red = false
			keys[key_count] = key; key_count += 1
		} else {
			if find_node(&tree[0], root, key) != 0 { search_results[search_count] = 1 } else { search_results[search_count] = 0 }
			search_count += 1
		}
	}
	insertion_sort(&keys[0], key_count)
	required := (2 + key_count + search_count) * 8
	if output == nil || capacity < c.size_t(required) do return CAPACITY_RESULT
	offset := 0
	write_i64_le(output, offset, i64(key_count)); offset += 8
	for index := 0; index < key_count; index += 1 { write_i64_le(output, offset, keys[index]); offset += 8 }
	write_i64_le(output, offset, i64(search_count)); offset += 8
	for index := 0; index < search_count; index += 1 { write_i64_le(output, offset, search_results[index]); offset += 8 }
	return i64(required)
}
