module weight_balanced_leaf_tree_order_statistics

import 'core:c'

const max_ops = i64(64)
const missing = i64(-129)

struct Tree {
mut:
	left [129]int
	right [129]int
	size [129]int
	free_next [129]int
	key [129]i64
	maximum [129]i64
	next_node int
	free_head int
}

fn allocate(mut tree Tree) int {
	mut node := 0
	if tree.free_head != 0 {
		node = tree.free_head
		tree.free_head = tree.free_next[node]
	} else {
		node = tree.next_node
		tree.next_node++
	}
	tree.left[node] = 0
	tree.right[node] = 0
	tree.size[node] = 0
	tree.free_next[node] = 0
	tree.key[node] = 0
	tree.maximum[node] = 0
	return node
}

fn release(mut tree Tree, node int) {
	tree.left[node] = 0
	tree.right[node] = 0
	tree.size[node] = 0
	tree.key[node] = 0
	tree.maximum[node] = 0
	tree.free_next[node] = tree.free_head
	tree.free_head = node
}

fn new_leaf(mut tree Tree, value i64) int {
	node := allocate(mut tree)
	tree.key[node] = value
	tree.maximum[node] = value
	tree.size[node] = 1
	return node
}

fn join_nodes(mut tree Tree, a int, b int) int {
	node := allocate(mut tree)
	tree.left[node] = a
	tree.right[node] = b
	tree.size[node] = tree.size[a] + tree.size[b]
	tree.maximum[node] = tree.maximum[b]
	return node
}

fn too_heavy(a int, b int) bool { return a > 3 * b }
fn merge_nodes(mut tree Tree, a int, b int) int

fn rebalance(mut tree Tree, node int) int {
	if tree.size[node] == 1 { return node }
	a := tree.left[node]
	b := tree.right[node]
	if too_heavy(tree.size[a], tree.size[b]) || too_heavy(tree.size[b], tree.size[a]) {
		release(mut tree, node)
		return merge_nodes(mut tree, a, b)
	}
	return node
}

fn merge_nodes(mut tree Tree, a int, b int) int {
	if a == 0 { return b }
	if b == 0 { return a }
	if too_heavy(tree.size[a], tree.size[b]) {
		x := tree.left[a]
		y := tree.right[a]
		release(mut tree, a)
		return rebalance(mut tree, join_nodes(mut tree, x, merge_nodes(mut tree, y, b)))
	}
	if too_heavy(tree.size[b], tree.size[a]) {
		x := tree.left[b]
		y := tree.right[b]
		release(mut tree, b)
		return rebalance(mut tree, join_nodes(mut tree, merge_nodes(mut tree, a, x), y))
	}
	return join_nodes(mut tree, a, b)
}

fn insert_key(mut tree Tree, node int, value i64) int {
	if node == 0 { return new_leaf(mut tree, value) }
	if tree.size[node] == 1 {
		if value <= tree.key[node] { return join_nodes(mut tree, new_leaf(mut tree, value), node) }
		return join_nodes(mut tree, node, new_leaf(mut tree, value))
	}
	if value <= tree.maximum[tree.left[node]] {
		tree.left[node] = insert_key(mut tree, tree.left[node], value)
	} else {
		tree.right[node] = insert_key(mut tree, tree.right[node], value)
	}
	tree.size[node] = tree.size[tree.left[node]] + tree.size[tree.right[node]]
	tree.maximum[node] = tree.maximum[tree.right[node]]
	return rebalance(mut tree, node)
}

fn remove_one(mut tree Tree, node int, value i64) (int, bool) {
	if node == 0 { return 0, false }
	if tree.size[node] == 1 {
		if tree.key[node] != value { return node, false }
		release(mut tree, node)
		return 0, true
	}
	mut child := 0
	mut removed := false
	if value <= tree.maximum[tree.left[node]] {
		child, removed = remove_one(mut tree, tree.left[node], value)
		tree.left[node] = child
	} else {
		child, removed = remove_one(mut tree, tree.right[node], value)
		tree.right[node] = child
	}
	if !removed { return node, false }
	a := tree.left[node]
	b := tree.right[node]
	if a == 0 || b == 0 {
		survivor := if a != 0 { a } else { b }
		release(mut tree, node)
		return survivor, true
	}
	tree.size[node] = tree.size[a] + tree.size[b]
	tree.maximum[node] = tree.maximum[b]
	return rebalance(mut tree, node), true
}

fn rank_less(tree &Tree, node int, value i64) i64 {
	if node == 0 { return 0 }
	if tree.size[node] == 1 { return if tree.key[node] < value { 1 } else { 0 } }
	a := tree.left[node]
	if value <= tree.maximum[a] { return rank_less(tree, a, value) }
	return i64(tree.size[a]) + rank_less(tree, tree.right[node], value)
}

fn kth(tree &Tree, start_node int, start_index i64) i64 {
	if start_node == 0 || start_index >= i64(tree.size[start_node]) { return missing }
	mut node := start_node
	mut index := start_index
	for tree.size[node] != 1 {
		a := tree.left[node]
		if index < i64(tree.size[a]) { node = a }
		else { index -= i64(tree.size[a]); node = tree.right[node] }
	}
	return tree.key[node]
}

fn predecessor(tree &Tree, node int, value i64) i64 {
	if node == 0 { return missing }
	if tree.size[node] == 1 { return if tree.key[node] < value { tree.key[node] } else { missing } }
	a := tree.left[node]
	if value <= tree.maximum[a] { return predecessor(tree, a, value) }
	answer := predecessor(tree, tree.right[node], value)
	return if answer == missing { tree.maximum[a] } else { answer }
}

fn successor(tree &Tree, node int, value i64) i64 {
	if node == 0 { return missing }
	if tree.size[node] == 1 { return if tree.key[node] > value { tree.key[node] } else { missing } }
	a := tree.left[node]
	return if value < tree.maximum[a] { successor(tree, a, value) } else { successor(tree, tree.right[node], value) }
}

@[export: 'weight_balanced_leaf_tree_order_statistics']
pub fn weight_balanced_leaf_tree_order_statistics(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 130 { return -1 }
	unsafe {
		q := input[0]
		if q < 0 || q > max_ops || length != usize(1 + 2 * q) { return -1 }
		for i := i64(0); i < q; i++ {
			op := input[1 + 2 * i]
			arg := input[2 + 2 * i]
			if op < 0 || op > 5 { return -1 }
			if op == 3 {
				if arg < 0 || arg >= max_ops { return -1 }
			} else if arg < -128 || arg > 127 { return -1 }
		}
		mut tree := Tree{next_node: 1}
		mut root := 0
		mut checksum := i64(0)
		for i := i64(0); i < q; i++ {
			op := input[1 + 2 * i]
			arg := input[2 + 2 * i]
			if op == 0 { root = insert_key(mut tree, root, arg) }
			else if op == 1 { root, _ = remove_one(mut tree, root, arg) }
			else {
				answer := i64(0)
				if op == 2 { answer = rank_less(tree, root, arg) }
				else if op == 3 { answer = kth(tree, root, arg) }
				else if op == 4 { answer = predecessor(tree, root, arg) }
				else { answer = successor(tree, root, arg) }
				checksum += (i + 1) * (answer - missing)
			}
		}
		return checksum
	}
}
