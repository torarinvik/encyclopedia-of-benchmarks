module size_balanced_ordered_set

import 'core:c'

const max_ops = i64(128)
const missing = i64(-1025)

struct SizeBalancedTree {
mut:
	key [129]i64
	size [129]int
	left [129]int
	right [129]int
	used int
}

fn subtree_size(tree &SizeBalancedTree, node int) int {
	if node == 0 { return 0 }
	return tree.size[node]
}

fn refresh(mut tree SizeBalancedTree, node int) {
	tree.size[node] = subtree_size(tree, tree.left[node]) + subtree_size(tree, tree.right[node]) + 1
}

fn rotate_right(mut tree SizeBalancedTree, root int) int {
	pivot := tree.left[root]
	tree.left[root] = tree.right[pivot]
	tree.right[pivot] = root
	refresh(mut tree, root)
	refresh(mut tree, pivot)
	return pivot
}

fn rotate_left(mut tree SizeBalancedTree, root int) int {
	pivot := tree.right[root]
	tree.right[root] = tree.left[pivot]
	tree.left[pivot] = root
	refresh(mut tree, root)
	refresh(mut tree, pivot)
	return pivot
}

fn maintain(mut tree SizeBalancedTree, root_start int, right_side bool) int {
	if root_start == 0 { return 0 }
	mut root := root_start
	if !right_side {
		if subtree_size(tree, tree.left[tree.left[root]]) > subtree_size(tree, tree.right[root]) {
			root = rotate_right(mut tree, root)
		} else if subtree_size(tree, tree.right[tree.left[root]]) > subtree_size(tree, tree.right[root]) {
			tree.left[root] = rotate_left(mut tree, tree.left[root])
			root = rotate_right(mut tree, root)
		} else { return root }
	} else {
		if subtree_size(tree, tree.right[tree.right[root]]) > subtree_size(tree, tree.left[root]) {
			root = rotate_left(mut tree, root)
		} else if subtree_size(tree, tree.left[tree.right[root]]) > subtree_size(tree, tree.left[root]) {
			tree.right[root] = rotate_right(mut tree, tree.right[root])
			root = rotate_left(mut tree, root)
		} else { return root }
	}
	tree.left[root] = maintain(mut tree, tree.left[root], false)
	tree.right[root] = maintain(mut tree, tree.right[root], true)
	root = maintain(mut tree, root, false)
	root = maintain(mut tree, root, true)
	return root
}

fn insert_key(mut tree SizeBalancedTree, root_start int, key i64) int {
	if root_start == 0 {
		tree.used++
		node := tree.used
		tree.key[node] = key
		tree.size[node] = 1
		return node
	}
	mut root := root_start
	if key < tree.key[root] {
		tree.left[root] = insert_key(mut tree, tree.left[root], key)
		refresh(mut tree, root)
		root = maintain(mut tree, root, false)
	} else if key > tree.key[root] {
		tree.right[root] = insert_key(mut tree, tree.right[root], key)
		refresh(mut tree, root)
		root = maintain(mut tree, root, true)
	}
	return root
}

fn rank(tree &SizeBalancedTree, root_start int, key i64) i64 {
	mut root := root_start
	mut answer := i64(0)
	for root != 0 {
		if key <= tree.key[root] { root = tree.left[root] }
		else {
			answer += i64(subtree_size(tree, tree.left[root]) + 1)
			root = tree.right[root]
		}
	}
	return answer
}

fn kth(tree &SizeBalancedTree, root_start int, index_start i64) i64 {
	mut root := root_start
	mut index := index_start
	for root != 0 {
		left_count := i64(subtree_size(tree, tree.left[root]))
		if index < left_count { root = tree.left[root] }
		else if index == left_count { return tree.key[root] }
		else { index -= left_count + 1; root = tree.right[root] }
	}
	return missing
}

fn predecessor(tree &SizeBalancedTree, root_start int, key i64) i64 {
	mut root := root_start
	mut answer := missing
	for root != 0 {
		if tree.key[root] < key { answer = tree.key[root]; root = tree.right[root] }
		else { root = tree.left[root] }
	}
	return answer
}

fn successor(tree &SizeBalancedTree, root_start int, key i64) i64 {
	mut root := root_start
	mut answer := missing
	for root != 0 {
		if tree.key[root] > key { answer = tree.key[root]; root = tree.left[root] }
		else { root = tree.right[root] }
	}
	return answer
}

@[export: 'size_balanced_ordered_set']
pub fn size_balanced_ordered_set(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 257 { return -1 }
	unsafe {
		q := input[0]
		if q < 0 || q > max_ops || length != usize(1 + 2 * q) { return -1 }
		for i := i64(0); i < q; i++ {
			op := input[1 + 2 * i]
			arg := input[2 + 2 * i]
			if op < 0 || op > 4 { return -1 }
			if op == 2 {
				if arg < 0 || arg > 127 { return -1 }
			} else if arg < -1024 || arg > 1023 { return -1 }
		}
		mut tree := SizeBalancedTree{}
		mut root := 0
		mut checksum := i64(0)
		for i := i64(0); i < q; i++ {
			op := input[1 + 2 * i]
			arg := input[2 + 2 * i]
			if op == 0 { root = insert_key(mut tree, root, arg) }
			else {
				answer := i64(0)
				if op == 1 { answer = rank(tree, root, arg) }
				else if op == 2 { answer = kth(tree, root, arg) }
				else if op == 3 { answer = predecessor(tree, root, arg) }
				else { answer = successor(tree, root, arg) }
				checksum += (i + 1) * (answer - missing)
			}
		}
		return checksum
	}
}
