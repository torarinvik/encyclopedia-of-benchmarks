package size_balanced_ordered_set

import "core:c"

MAX_OPS :: 128
MAX_NODES :: 129
MISSING :: i64(-1025)

Tree :: struct {
	key: [MAX_NODES]i64,
	size: [MAX_NODES]int,
	left: [MAX_NODES]int,
	right: [MAX_NODES]int,
	used: int,
}

subtree_size :: proc(tree: ^Tree, node: int) -> int {
	if node == 0 do return 0
	return tree.size[node]
}

refresh :: proc(tree: ^Tree, node: int) {
	tree.size[node] = subtree_size(tree, tree.left[node]) + subtree_size(tree, tree.right[node]) + 1
}

rotate_right :: proc(tree: ^Tree, root: int) -> int {
	pivot := tree.left[root]
	tree.left[root] = tree.right[pivot]
	tree.right[pivot] = root
	refresh(tree, root)
	refresh(tree, pivot)
	return pivot
}

rotate_left :: proc(tree: ^Tree, root: int) -> int {
	pivot := tree.right[root]
	tree.right[root] = tree.left[pivot]
	tree.left[pivot] = root
	refresh(tree, root)
	refresh(tree, pivot)
	return pivot
}

maintain :: proc(tree: ^Tree, root_input: int, right_side: bool) -> int {
	if root_input == 0 do return 0
	root := root_input
	if !right_side {
		if subtree_size(tree, tree.left[tree.left[root]]) > subtree_size(tree, tree.right[root]) {
			root = rotate_right(tree, root)
		} else if subtree_size(tree, tree.right[tree.left[root]]) > subtree_size(tree, tree.right[root]) {
			tree.left[root] = rotate_left(tree, tree.left[root])
			root = rotate_right(tree, root)
		} else {
			return root
		}
	} else {
		if subtree_size(tree, tree.right[tree.right[root]]) > subtree_size(tree, tree.left[root]) {
			root = rotate_left(tree, root)
		} else if subtree_size(tree, tree.left[tree.right[root]]) > subtree_size(tree, tree.left[root]) {
			tree.right[root] = rotate_right(tree, tree.right[root])
			root = rotate_left(tree, root)
		} else {
			return root
		}
	}
	tree.left[root] = maintain(tree, tree.left[root], false)
	tree.right[root] = maintain(tree, tree.right[root], true)
	root = maintain(tree, root, false)
	root = maintain(tree, root, true)
	return root
}

insert_key :: proc(tree: ^Tree, root_input: int, key: i64) -> int {
	if root_input == 0 {
		tree.used += 1
		node := tree.used
		tree.key[node] = key
		tree.size[node] = 1
		return node
	}
	root := root_input
	if key < tree.key[root] {
		tree.left[root] = insert_key(tree, tree.left[root], key)
		refresh(tree, root)
		root = maintain(tree, root, false)
	} else if key > tree.key[root] {
		tree.right[root] = insert_key(tree, tree.right[root], key)
		refresh(tree, root)
		root = maintain(tree, root, true)
	}
	return root
}

rank :: proc(tree: ^Tree, root_input: int, key: i64) -> i64 {
	root := root_input
	answer := i64(0)
	for root != 0 {
		if key <= tree.key[root] {
			root = tree.left[root]
		} else {
			answer += i64(subtree_size(tree, tree.left[root]) + 1)
			root = tree.right[root]
		}
	}
	return answer
}

kth :: proc(tree: ^Tree, root_input: int, index_input: i64) -> i64 {
	root := root_input
	index := index_input
	for root != 0 {
		left_count := i64(subtree_size(tree, tree.left[root]))
		if index < left_count {
			root = tree.left[root]
		} else if index == left_count {
			return tree.key[root]
		} else {
			index -= left_count + 1
			root = tree.right[root]
		}
	}
	return MISSING
}

predecessor :: proc(tree: ^Tree, root_input: int, key: i64) -> i64 {
	root := root_input
	answer := MISSING
	for root != 0 {
		if tree.key[root] < key {
			answer = tree.key[root]
			root = tree.right[root]
		} else {
			root = tree.left[root]
		}
	}
	return answer
}

successor :: proc(tree: ^Tree, root_input: int, key: i64) -> i64 {
	root := root_input
	answer := MISSING
	for root != 0 {
		if tree.key[root] > key {
			answer = tree.key[root]
			root = tree.left[root]
		} else {
			root = tree.right[root]
		}
	}
	return answer
}

@(export)
size_balanced_ordered_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 257 do return -1
	q := input[0]
	if q < 0 || q > MAX_OPS || length != c.size_t(1 + 2 * q) do return -1
	for i := i64(0); i < q; i += 1 {
		op := input[1 + 2 * i]
		arg := input[2 + 2 * i]
		if op < 0 || op > 4 do return -1
		if op == 2 {
			if arg < 0 || arg > 127 do return -1
		} else if arg < -1024 || arg > 1023 do return -1
	}
	tree := Tree{}
	root := 0
	checksum := i64(0)
	for i := i64(0); i < q; i += 1 {
		op := input[1 + 2 * i]
		arg := input[2 + 2 * i]
		if op == 0 {
			root = insert_key(&tree, root, arg)
		} else {
			answer := i64(0)
			if op == 1 { answer = rank(&tree, root, arg) }
			else if op == 2 { answer = kth(&tree, root, arg) }
			else if op == 3 { answer = predecessor(&tree, root, arg) }
			else { answer = successor(&tree, root, arg) }
			checksum += (i + 1) * (answer - MISSING)
		}
	}
	return checksum
}
