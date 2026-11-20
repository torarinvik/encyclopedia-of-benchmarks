package weight_balanced_leaf_tree_order_statistics

import "core:c"

MAX_OPS :: 64
MISSING :: i64(-129)
NODE_CAPACITY :: 129

Tree :: struct {
	left: [NODE_CAPACITY]int,
	right: [NODE_CAPACITY]int,
	size: [NODE_CAPACITY]int,
	free_next: [NODE_CAPACITY]int,
	key: [NODE_CAPACITY]i64,
	maximum: [NODE_CAPACITY]i64,
	next_node: int,
	free_head: int,
}

allocate :: proc(tree: ^Tree) -> int {
	node: int
	if tree.free_head != 0 {
		node = tree.free_head
		tree.free_head = tree.free_next[node]
	} else {
		node = tree.next_node
		tree.next_node += 1
	}
	tree.left[node] = 0
	tree.right[node] = 0
	tree.size[node] = 0
	tree.free_next[node] = 0
	tree.key[node] = 0
	tree.maximum[node] = 0
	return node
}

release :: proc(tree: ^Tree, node: int) {
	tree.left[node] = 0
	tree.right[node] = 0
	tree.size[node] = 0
	tree.key[node] = 0
	tree.maximum[node] = 0
	tree.free_next[node] = tree.free_head
	tree.free_head = node
}

new_leaf :: proc(tree: ^Tree, value: i64) -> int {
	node := allocate(tree)
	tree.key[node] = value
	tree.maximum[node] = value
	tree.size[node] = 1
	return node
}

join_nodes :: proc(tree: ^Tree, a, b: int) -> int {
	node := allocate(tree)
	tree.left[node] = a
	tree.right[node] = b
	tree.size[node] = tree.size[a] + tree.size[b]
	tree.maximum[node] = tree.maximum[b]
	return node
}

too_heavy :: proc(a, b: int) -> bool { return a > 3*b }
merge_nodes :: proc(tree: ^Tree, a, b: int) -> int

rebalance :: proc(tree: ^Tree, node: int) -> int {
	if tree.size[node] == 1 do return node
	a, b := tree.left[node], tree.right[node]
	if too_heavy(tree.size[a], tree.size[b]) || too_heavy(tree.size[b], tree.size[a]) {
		release(tree, node)
		return merge_nodes(tree, a, b)
	}
	return node
}

merge_nodes :: proc(tree: ^Tree, a, b: int) -> int {
	if a == 0 do return b
	if b == 0 do return a
	if too_heavy(tree.size[a], tree.size[b]) {
		x, y := tree.left[a], tree.right[a]
		release(tree, a)
		return rebalance(tree, join_nodes(tree, x, merge_nodes(tree, y, b)))
	}
	if too_heavy(tree.size[b], tree.size[a]) {
		x, y := tree.left[b], tree.right[b]
		release(tree, b)
		return rebalance(tree, join_nodes(tree, merge_nodes(tree, a, x), y))
	}
	return join_nodes(tree, a, b)
}

insert_key :: proc(tree: ^Tree, node: int, value: i64) -> int {
	if node == 0 do return new_leaf(tree, value)
	if tree.size[node] == 1 {
		if value <= tree.key[node] do return join_nodes(tree, new_leaf(tree, value), node)
		return join_nodes(tree, node, new_leaf(tree, value))
	}
	if value <= tree.maximum[tree.left[node]] {
		tree.left[node] = insert_key(tree, tree.left[node], value)
	} else {
		tree.right[node] = insert_key(tree, tree.right[node], value)
	}
	tree.size[node] = tree.size[tree.left[node]] + tree.size[tree.right[node]]
	tree.maximum[node] = tree.maximum[tree.right[node]]
	return rebalance(tree, node)
}

remove_one :: proc(tree: ^Tree, node: int, value: i64) -> (int, bool) {
	if node == 0 do return 0, false
	if tree.size[node] == 1 {
		if tree.key[node] != value do return node, false
		release(tree, node)
		return 0, true
	}
	removed: bool
	if value <= tree.maximum[tree.left[node]] {
		child, did_remove := remove_one(tree, tree.left[node], value)
		tree.left[node] = child
		removed = did_remove
	} else {
		child, did_remove := remove_one(tree, tree.right[node], value)
		tree.right[node] = child
		removed = did_remove
	}
	if !removed do return node, false
	a, b := tree.left[node], tree.right[node]
	if a == 0 || b == 0 {
		child := a
		if child == 0 do child = b
		release(tree, node)
		return child, true
	}
	tree.size[node] = tree.size[a] + tree.size[b]
	tree.maximum[node] = tree.maximum[b]
	return rebalance(tree, node), true
}

rank_less :: proc(tree: ^Tree, node: int, value: i64) -> i64 {
	if node == 0 do return 0
	if tree.size[node] == 1 {
		if tree.key[node] < value do return 1
		return 0
	}
	a := tree.left[node]
	if value <= tree.maximum[a] do return rank_less(tree, a, value)
	return i64(tree.size[a]) + rank_less(tree, tree.right[node], value)
}

kth :: proc(tree: ^Tree, start_node: int, start_index: i64) -> i64 {
	if start_node == 0 || start_index >= i64(tree.size[start_node]) do return MISSING
	node, index := start_node, start_index
	for tree.size[node] != 1 {
		a := tree.left[node]
		if index < i64(tree.size[a]) do node = a
		else { index -= i64(tree.size[a]); node = tree.right[node] }
	}
	return tree.key[node]
}

predecessor :: proc(tree: ^Tree, node: int, value: i64) -> i64 {
	if node == 0 do return MISSING
	if tree.size[node] == 1 {
		if tree.key[node] < value do return tree.key[node]
		return MISSING
	}
	a := tree.left[node]
	if value <= tree.maximum[a] do return predecessor(tree, a, value)
	answer := predecessor(tree, tree.right[node], value)
	if answer == MISSING do return tree.maximum[a]
	return answer
}

successor :: proc(tree: ^Tree, node: int, value: i64) -> i64 {
	if node == 0 do return MISSING
	if tree.size[node] == 1 {
		if tree.key[node] > value do return tree.key[node]
		return MISSING
	}
	a := tree.left[node]
	if value < tree.maximum[a] do return successor(tree, a, value)
	return successor(tree, tree.right[node], value)
}

@(export)
weight_balanced_leaf_tree_order_statistics :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 130 do return -1
	q := input[0]
	if q < 0 || q > MAX_OPS || length != c.size_t(1 + 2*q) do return -1
	for i := i64(0); i < q; i += 1 {
		op, arg := input[1 + 2*i], input[2 + 2*i]
		if op < 0 || op > 5 do return -1
		if op == 3 {
			if arg < 0 || arg >= MAX_OPS do return -1
		} else if arg < -128 || arg > 127 do return -1
	}
	tree := Tree{next_node = 1}
	root := 0
	checksum := i64(0)
	for i := i64(0); i < q; i += 1 {
		op, arg := input[1 + 2*i], input[2 + 2*i]
		if op == 0 { root = insert_key(&tree, root, arg) }
		else if op == 1 { root, _ = remove_one(&tree, root, arg) }
		else {
			answer := i64(0)
			if op == 2 { answer = rank_less(&tree, root, arg) }
			else if op == 3 { answer = kth(&tree, root, arg) }
			else if op == 4 { answer = predecessor(&tree, root, arg) }
			else { answer = successor(&tree, root, arg) }
			checksum += (i + 1) * (answer - MISSING)
		}
	}
	return checksum
}
