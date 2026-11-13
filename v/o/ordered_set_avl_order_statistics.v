module ordered_set_avl_order_statistics

import 'core:c'

const max_items = i64(32)
const max_ops = i64(32)
const max_key = i64(1000)

struct AvlTree {
mut:
	key [65]i64
	height [65]int
	size [65]int
	left [65]int
	right [65]int
	used int
}

fn node_height(tree &AvlTree, node int) int { if node == 0 { return 0 }; return tree.height[node] }
fn node_size(tree &AvlTree, node int) int { if node == 0 { return 0 }; return tree.size[node] }

fn refresh(mut tree AvlTree, node int) {
	lh := node_height(tree, tree.left[node])
	rh := node_height(tree, tree.right[node])
	tree.height[node] = (if lh > rh { lh } else { rh }) + 1
	tree.size[node] = node_size(tree, tree.left[node]) + node_size(tree, tree.right[node]) + 1
}
fn rotate_right(mut tree AvlTree, root int) int {
	pivot := tree.left[root]
	tree.left[root] = tree.right[pivot]
	tree.right[pivot] = root
	refresh(mut tree, root)
	refresh(mut tree, pivot)
	return pivot
}
fn rotate_left(mut tree AvlTree, root int) int {
	pivot := tree.right[root]
	tree.right[root] = tree.left[pivot]
	tree.left[pivot] = root
	refresh(mut tree, root)
	refresh(mut tree, pivot)
	return pivot
}
fn rebalance(mut tree AvlTree, root int) int {
	refresh(mut tree, root)
	difference := node_height(tree, tree.left[root]) - node_height(tree, tree.right[root])
	if difference > 1 {
		child := tree.left[root]
		if node_height(tree, tree.left[child]) < node_height(tree, tree.right[child]) {
			tree.left[root] = rotate_left(mut tree, child)
		}
		return rotate_right(mut tree, root)
	}
	if difference < -1 {
		child := tree.right[root]
		if node_height(tree, tree.right[child]) < node_height(tree, tree.left[child]) {
			tree.right[root] = rotate_right(mut tree, child)
		}
		return rotate_left(mut tree, root)
	}
	return root
}
fn insert_key(mut tree AvlTree, root int, key i64) int {
	if root == 0 {
		tree.used++
		node := tree.used
		tree.key[node] = key
		tree.height[node] = 1
		tree.size[node] = 1
		return node
	}
	if key < tree.key[root] { tree.left[root] = insert_key(mut tree, tree.left[root], key) }
	else if key > tree.key[root] { tree.right[root] = insert_key(mut tree, tree.right[root], key) }
	else { return root }
	return rebalance(mut tree, root)
}
fn minimum_node(tree &AvlTree, root_start int) int {
	mut root := root_start
	for tree.left[root] != 0 { root = tree.left[root] }
	return root
}
fn erase_key(mut tree AvlTree, root int, key i64) int {
	if root == 0 { return 0 }
	if key < tree.key[root] { tree.left[root] = erase_key(mut tree, tree.left[root], key) }
	else if key > tree.key[root] { tree.right[root] = erase_key(mut tree, tree.right[root], key) }
	else if tree.left[root] == 0 { return tree.right[root] }
	else if tree.right[root] == 0 { return tree.left[root] }
	else {
		next := minimum_node(tree, tree.right[root])
		tree.key[root] = tree.key[next]
		tree.right[root] = erase_key(mut tree, tree.right[root], tree.key[next])
	}
	return rebalance(mut tree, root)
}
fn kth(tree &AvlTree, root_start int, rank_start i64) i64 {
	if rank_start < 1 || rank_start > i64(node_size(tree, root_start)) { return -1 }
	mut root := root_start
	mut rank := rank_start
	for root != 0 {
		left_count := i64(node_size(tree, tree.left[root]))
		if rank == left_count + 1 { return tree.key[root] }
		if rank <= left_count { root = tree.left[root] } else { rank -= left_count + 1; root = tree.right[root] }
	}
	return -1
}
fn count_le(tree &AvlTree, root_start int, key i64) i64 {
	mut root := root_start
	mut count := i64(0)
	for root != 0 {
		if tree.key[root] <= key { count += i64(node_size(tree, tree.left[root])) + 1; root = tree.right[root] }
		else { root = tree.left[root] }
	}
	return count
}
fn predecessor(tree &AvlTree, root_start int, key i64) i64 {
	mut root := root_start
	mut answer := i64(-1)
	for root != 0 {
		if tree.key[root] <= key { answer = tree.key[root]; root = tree.right[root] }
		else { root = tree.left[root] }
	}
	return answer
}
fn successor(tree &AvlTree, root_start int, key i64) i64 {
	mut root := root_start
	mut answer := i64(-1)
	for root != 0 {
		if tree.key[root] >= key { answer = tree.key[root]; root = tree.left[root] }
		else { root = tree.right[root] }
	}
	return answer
}

@[export: 'ordered_set_avl_order_statistics']
pub fn ordered_set_avl_order_statistics(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 99 { return -1 }
	unsafe {
		n := input[0]
		q := input[1]
		if n < 0 || n > max_items || q < 0 || q > max_ops || length != usize(2 + n + 2 * q) { return -1 }
		for i := i64(0); i < n; i++ {
			key := input[2 + i]
			if key < 0 || key > max_key || (i > 0 && input[1 + i] >= key) { return -1 }
		}
		for i := i64(0); i < q; i++ {
			op := input[2 + n + 2 * i]
			key := input[3 + n + 2 * i]
			if op < 0 || op > 5 || key < 0 || key > max_key || (op == 2 && key < 1) { return -1 }
		}
		mut tree := AvlTree{}
		mut root := 0
		for i := i64(0); i < n; i++ { root = insert_key(mut tree, root, input[2 + i]) }
		mut checksum := i64(0)
		mut query_index := i64(0)
		for i := i64(0); i < q; i++ {
			op := input[2 + n + 2 * i]
			key := input[3 + n + 2 * i]
			if op == 0 { root = insert_key(mut tree, root, key) }
			else if op == 1 { root = erase_key(mut tree, root, key) }
			else {
				answer := if op == 2 { kth(tree, root, key) } else if op == 3 { count_le(tree, root, key) } else if op == 4 { predecessor(tree, root, key) } else { successor(tree, root, key) }
				query_index++
				checksum += query_index * (answer + 1)
			}
		}
		return checksum
	}
}
