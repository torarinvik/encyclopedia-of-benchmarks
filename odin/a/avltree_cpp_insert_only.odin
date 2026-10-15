package avltree_cpp_insert_only

import "core:c"

MAX_NODES :: 256

avl_height :: proc "contextless" (root: i32, left, right: [^]i32) -> int {
	if root < 0 do return 0
	left_height := avl_height(left[root], left, right)
	right_height := avl_height(right[root], left, right)
	return 1 + max(left_height, right_height)
}

avl_balance :: proc "contextless" (root: i32, left, right: [^]i32) -> int {
	return avl_height(left[root], left, right) - avl_height(right[root], left, right)
}

rotate_right :: proc "contextless" (root: i32, left, right: [^]i32) -> i32 {
	pivot := left[root]
	moved := right[pivot]
	right[pivot] = root
	left[root] = moved
	return pivot
}

rotate_left :: proc "contextless" (root: i32, left, right: [^]i32) -> i32 {
	pivot := right[root]
	moved := left[pivot]
	left[pivot] = root
	right[root] = moved
	return pivot
}

insert_node :: proc "contextless" (root: i32, key: i32, keys, left, right: [^]i32,
		next_node: ^int) -> i32 {
	if root < 0 {
		node := i32(next_node^)
		next_node^ += 1
		keys[node] = key
		left[node] = -1
		right[node] = -1
		return node
	}
	if key < keys[root] {
		left[root] = insert_node(left[root], key, keys, left, right, next_node)
	} else {
		right[root] = insert_node(right[root], key, keys, left, right, next_node)
	}
	balance := avl_balance(root, left, right)
	if balance > 1 {
		if avl_balance(left[root], left, right) < 0 {
			left[root] = rotate_left(left[root], left, right)
		}
		return rotate_right(root, left, right)
	}
	if balance < -1 {
		if avl_balance(right[root], left, right) > 0 {
			right[root] = rotate_right(right[root], left, right)
		}
		return rotate_left(root, left, right)
	}
	return root
}

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 {
		output[position*4+byte] = u8(bits >> u32(8*byte))
	}
}

emit_inorder :: proc "contextless" (root: i32, keys, left, right: [^]i32,
		output: [^]u8, position: ^int) {
	if root < 0 do return
	emit_inorder(left[root], keys, left, right, output, position)
	store_i32_le(output, position^, keys[root])
	position^ += 1
	emit_inorder(right[root], keys, left, right, output, position)
}

@(export)
avltree_cpp_insert_only :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_NODES + 1 do return -1
	if input[0] < 1 || input[0] > MAX_NODES do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	for index := 0; index < n; index += 1 {
		key := input[index+1]
		if key < -2147483648 || key > 2147483647 do return -1
		for previous := 0; previous < index; previous += 1 {
			if input[previous+1] == key do return -1
		}
	}
	required := c.size_t(n * 4)
	if output == nil || output_capacity < required do return -2

	keys: [MAX_NODES]i32 = {}
	left: [MAX_NODES]i32
	right: [MAX_NODES]i32
	for index := 0; index < MAX_NODES; index += 1 {
		left[index] = -1
		right[index] = -1
	}
	next_node := 0
	root := i32(-1)
	for index := 0; index < n; index += 1 {
		root = insert_node(root, i32(input[index+1]), &keys[0], &left[0], &right[0], &next_node)
	}
	position := 0
	emit_inorder(root, &keys[0], &left[0], &right[0], output, &position)
	return i64(position)
}
