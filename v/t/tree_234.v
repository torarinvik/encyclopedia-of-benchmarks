module tree_234

import core:c

const max_ops = 128
const max_nodes = 2049
const max_output_words = 130

struct Node {
	mut:
	keys [3]i64
	children [4]int
	key_count int
	leaf bool
}
struct Tree {
	mut:
	nodes [max_nodes]Node
	node_count int
	root int
	final_keys [max_ops]i64
	final_count int
}

fn new_node(mut tree Tree, leaf bool) int {
	index := tree.node_count
	tree.node_count++
	tree.nodes[index].key_count = 0
	tree.nodes[index].leaf = leaf
	for i in 0 .. 4 { tree.nodes[index].children[i] = -1 }
	return index
}
fn contains(tree &Tree, node_index int, key i64) bool {
	if node_index < 0 { return false }
	node := tree.nodes[node_index]
	mut i := 0
	for i < node.key_count && key > node.keys[i] { i++ }
	if i < node.key_count && key == node.keys[i] { return true }
	if node.leaf { return false }
	return contains(tree, node.children[i], key)
}
fn split_child(mut tree Tree, parent_index int, child_position int) {
	child_index := tree.nodes[parent_index].children[child_position]
	right_index := new_node(mut tree, tree.nodes[child_index].leaf)
	middle := tree.nodes[child_index].keys[1]
	tree.nodes[right_index].key_count = 1
	tree.nodes[right_index].keys[0] = tree.nodes[child_index].keys[2]
	if !tree.nodes[child_index].leaf {
		tree.nodes[right_index].children[0] = tree.nodes[child_index].children[2]
		tree.nodes[right_index].children[1] = tree.nodes[child_index].children[3]
	}
	tree.nodes[child_index].key_count = 1
	count := tree.nodes[parent_index].key_count
	for i := count; i > child_position; i-- { tree.nodes[parent_index].keys[i] = tree.nodes[parent_index].keys[i - 1] }
	for i := count + 1; i > child_position + 1; i-- { tree.nodes[parent_index].children[i] = tree.nodes[parent_index].children[i - 1] }
	tree.nodes[parent_index].keys[child_position] = middle
	tree.nodes[parent_index].children[child_position + 1] = right_index
	tree.nodes[parent_index].key_count++
}
fn insert_nonfull(mut tree Tree, node_index int, key i64) {
	mut i := tree.nodes[node_index].key_count - 1
	if tree.nodes[node_index].leaf {
		for i >= 0 && key < tree.nodes[node_index].keys[i] {
			tree.nodes[node_index].keys[i + 1] = tree.nodes[node_index].keys[i]
			i--
		}
		tree.nodes[node_index].keys[i + 1] = key
		tree.nodes[node_index].key_count++
		return
	}
	for i >= 0 && key < tree.nodes[node_index].keys[i] { i-- }
	i++
	if tree.nodes[tree.nodes[node_index].children[i]].key_count == 3 {
		split_child(mut tree, node_index, i)
		if key > tree.nodes[node_index].keys[i] { i++ }
	}
	insert_nonfull(mut tree, tree.nodes[node_index].children[i], key)
}
fn insert_key(mut tree Tree, key i64) {
	if contains(tree, tree.root, key) { return }
	if tree.root < 0 {
		tree.root = new_node(mut tree, true)
		tree.nodes[tree.root].keys[0] = key
		tree.nodes[tree.root].key_count = 1
		return
	}
	if tree.nodes[tree.root].key_count == 3 {
		old_root := tree.root
		new_root := new_node(mut tree, false)
		tree.nodes[new_root].children[0] = old_root
		tree.root = new_root
		split_child(mut tree, new_root, 0)
	}
	insert_nonfull(mut tree, tree.root, key)
}
fn find_key(node Node, key i64) int {
	mut i := 0
	for i < node.key_count && node.keys[i] < key { i++ }
	if i < node.key_count && node.keys[i] == key { return i }
	return -1
}
fn predecessor(tree &Tree, node_index int) i64 {
	mut index := node_index
	for !tree.nodes[index].leaf { index = tree.nodes[index].children[tree.nodes[index].key_count] }
	return tree.nodes[index].keys[tree.nodes[index].key_count - 1]
}
fn successor(tree &Tree, node_index int) i64 {
	mut index := node_index
	for !tree.nodes[index].leaf { index = tree.nodes[index].children[0] }
	return tree.nodes[index].keys[0]
}
fn merge_children(mut tree Tree, parent_index int, key_index int) int {
	left_index := tree.nodes[parent_index].children[key_index]
	right_index := tree.nodes[parent_index].children[key_index + 1]
	left_count := tree.nodes[left_index].key_count
	tree.nodes[left_index].keys[left_count] = tree.nodes[parent_index].keys[key_index]
	for i in 0 .. tree.nodes[right_index].key_count {
		tree.nodes[left_index].keys[left_count + 1 + i] = tree.nodes[right_index].keys[i]
	}
	if !tree.nodes[left_index].leaf {
		for i in 0 .. tree.nodes[right_index].key_count + 1 {
			tree.nodes[left_index].children[left_count + 1 + i] = tree.nodes[right_index].children[i]
		}
	}
	tree.nodes[left_index].key_count = left_count + 1 + tree.nodes[right_index].key_count
	parent_count := tree.nodes[parent_index].key_count
	for i := key_index; i < parent_count - 1; i++ { tree.nodes[parent_index].keys[i] = tree.nodes[parent_index].keys[i + 1] }
	for i := key_index + 1; i < parent_count; i++ { tree.nodes[parent_index].children[i] = tree.nodes[parent_index].children[i + 1] }
	tree.nodes[parent_index].key_count--
	return left_index
}
fn borrow_previous(mut tree Tree, parent_index int, child_index int) {
	child := tree.nodes[parent_index].children[child_index]
	sibling := tree.nodes[parent_index].children[child_index - 1]
	count := tree.nodes[child].key_count
	for i := count; i > 0; i-- { tree.nodes[child].keys[i] = tree.nodes[child].keys[i - 1] }
	if !tree.nodes[child].leaf {
		for i := count + 1; i > 0; i-- { tree.nodes[child].children[i] = tree.nodes[child].children[i - 1] }
		tree.nodes[child].children[0] = tree.nodes[sibling].children[tree.nodes[sibling].key_count]
	}
	tree.nodes[child].keys[0] = tree.nodes[parent_index].keys[child_index - 1]
	last := tree.nodes[sibling].key_count - 1
	tree.nodes[parent_index].keys[child_index - 1] = tree.nodes[sibling].keys[last]
	tree.nodes[child].key_count++
	tree.nodes[sibling].key_count--
}
fn borrow_next(mut tree Tree, parent_index int, child_index int) {
	child := tree.nodes[parent_index].children[child_index]
	sibling := tree.nodes[parent_index].children[child_index + 1]
	count := tree.nodes[child].key_count
	tree.nodes[child].keys[count] = tree.nodes[parent_index].keys[child_index]
	if !tree.nodes[child].leaf { tree.nodes[child].children[count + 1] = tree.nodes[sibling].children[0] }
	tree.nodes[parent_index].keys[child_index] = tree.nodes[sibling].keys[0]
	sibling_count := tree.nodes[sibling].key_count
	for i in 0 .. sibling_count - 1 { tree.nodes[sibling].keys[i] = tree.nodes[sibling].keys[i + 1] }
	if !tree.nodes[sibling].leaf {
		for i in 0 .. sibling_count { tree.nodes[sibling].children[i] = tree.nodes[sibling].children[i + 1] }
	}
	tree.nodes[child].key_count++
	tree.nodes[sibling].key_count--
}
fn remove_from_node(mut tree Tree, node_index int, key i64) {
	key_index := find_key(tree.nodes[node_index], key)
	if key_index >= 0 {
		if tree.nodes[node_index].leaf {
			count := tree.nodes[node_index].key_count
			for i := key_index; i < count - 1; i++ { tree.nodes[node_index].keys[i] = tree.nodes[node_index].keys[i + 1] }
			tree.nodes[node_index].key_count--
			return
		}
		left := tree.nodes[node_index].children[key_index]
		right := tree.nodes[node_index].children[key_index + 1]
		if tree.nodes[left].key_count >= 2 {
			replacement := predecessor(tree, left)
			tree.nodes[node_index].keys[key_index] = replacement
			remove_from_node(mut tree, left, replacement)
		} else if tree.nodes[right].key_count >= 2 {
			replacement := successor(tree, right)
			tree.nodes[node_index].keys[key_index] = replacement
			remove_from_node(mut tree, right, replacement)
		} else {
			merged := merge_children(mut tree, node_index, key_index)
			remove_from_node(mut tree, merged, key)
		}
		return
	}
	if tree.nodes[node_index].leaf { return }
	mut child_index := 0
	for child_index < tree.nodes[node_index].key_count && key > tree.nodes[node_index].keys[child_index] { child_index++ }
	mut child := tree.nodes[node_index].children[child_index]
	if tree.nodes[child].key_count == 1 {
		if child_index > 0 && tree.nodes[tree.nodes[node_index].children[child_index - 1]].key_count >= 2 {
			borrow_previous(mut tree, node_index, child_index)
		} else if child_index < tree.nodes[node_index].key_count && tree.nodes[tree.nodes[node_index].children[child_index + 1]].key_count >= 2 {
			borrow_next(mut tree, node_index, child_index)
		} else if child_index < tree.nodes[node_index].key_count {
			child = merge_children(mut tree, node_index, child_index)
		} else {
			child = merge_children(mut tree, node_index, child_index - 1)
		}
	}
	remove_from_node(mut tree, child, key)
}
fn remove_key(mut tree Tree, key i64) i64 {
	if !contains(tree, tree.root, key) { return 0 }
	remove_from_node(mut tree, tree.root, key)
	if tree.root >= 0 && tree.nodes[tree.root].key_count == 0 {
		old_root := tree.root
		if tree.nodes[old_root].leaf { tree.root = -1 } else { tree.root = tree.nodes[old_root].children[0] }
	}
	return 1
}
fn traverse(mut tree Tree, node_index int) {
	if node_index < 0 { return }
	for i in 0 .. tree.nodes[node_index].key_count {
		if !tree.nodes[node_index].leaf { traverse(mut tree, tree.nodes[node_index].children[i]) }
		tree.final_keys[tree.final_count] = tree.nodes[node_index].keys[i]
		tree.final_count++
	}
	if !tree.nodes[node_index].leaf { traverse(mut tree, tree.nodes[node_index].children[tree.nodes[node_index].key_count]) }
}
fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset + b] = u8(bits >> (8 * b)) } }
}

@[export: 'tree_234']
pub fn tree_234(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 258 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_ops { return -1 }
		ops := int(input[0])
		if length != usize(1 + 2 * ops) { return -1 }
		for i in 0 .. ops { op := input[1 + 2 * i]; if op != 0 && op != 1 { return -1 } }
		mut tree := Tree{}
		tree.root = -1
		mut remove_results := [max_ops]i64{}
		mut remove_count := 0
		for i in 0 .. ops {
			op := input[1 + 2 * i]
			key := input[2 + 2 * i]
			if op == 0 { insert_key(mut tree, key) } else { remove_results[remove_count] = remove_key(mut tree, key); remove_count++ }
		}
		traverse(mut tree, tree.root)
		mut words := [max_output_words]i64{}
		words[0] = i64(remove_count)
		for i in 0 .. remove_count { words[1 + i] = remove_results[i] }
		words[1 + remove_count] = i64(tree.final_count)
		for i in 0 .. tree.final_count { words[2 + remove_count + i] = tree.final_keys[i] }
		word_count := 2 + remove_count + tree.final_count
		output_bytes := word_count * 8
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. word_count { put_i64(mut output, i * 8, words[i]) }
		return i64(output_bytes)
	}
}
