module b_tree

const max_node_count = 257
const max_node_keys = 15
const max_node_children = 16
const max_key_count = 256
const max_operations = 511
const offset = i64(1000000)
const hash_mod = i64(1000000007)

struct BTree {
	mut:
	keys [max_node_count][max_node_keys]i64
	children [max_node_count][max_node_children]int
	key_count [max_node_count]int
	leaf [max_node_count]bool
	used_nodes int
	root int
	min_degree int
}

fn split_child(mut tree BTree, parent int, child_index int) bool {
	if tree.used_nodes >= max_node_count { return false }
	child := tree.children[parent][child_index]
	degree := tree.min_degree
	sibling := tree.used_nodes
	tree.used_nodes++
	tree.leaf[sibling] = tree.leaf[child]
	tree.key_count[sibling] = degree - 1
	for i in 0 .. degree - 1 { tree.keys[sibling][i] = tree.keys[child][degree + i] }
	if !tree.leaf[child] {
		for i in 0 .. degree { tree.children[sibling][i] = tree.children[child][degree + i] }
	}
	parent_count := tree.key_count[parent]
	for i := parent_count + 1; i > child_index + 1; i-- { tree.children[parent][i] = tree.children[parent][i - 1] }
	tree.children[parent][child_index + 1] = sibling
	for i := parent_count; i > child_index; i-- { tree.keys[parent][i] = tree.keys[parent][i - 1] }
	tree.keys[parent][child_index] = tree.keys[child][degree - 1]
	tree.key_count[child] = degree - 1
	tree.key_count[parent] = parent_count + 1
	return true
}

fn insert_non_full(mut tree BTree, node int, key i64) bool {
	mut index := tree.key_count[node]
	if tree.leaf[node] {
		for index > 0 && key <= tree.keys[node][index - 1] {
			tree.keys[node][index] = tree.keys[node][index - 1]
			index--
		}
		tree.keys[node][index] = key
		tree.key_count[node]++
		return true
	}
	for index > 0 && key <= tree.keys[node][index - 1] { index-- }
	child := tree.children[node][index]
	if tree.key_count[child] == 2 * tree.min_degree - 1 {
		if !split_child(mut tree, node, index) { return false }
		if tree.keys[node][index] < key { index++ }
	}
	return insert_non_full(mut tree, tree.children[node][index], key)
}

fn insert_key(mut tree BTree, key i64) bool {
	if tree.key_count[tree.root] == 2 * tree.min_degree - 1 {
		if tree.used_nodes + 2 > max_node_count { return false }
		old_root := tree.root
		new_root := tree.used_nodes
		tree.used_nodes++
		tree.leaf[new_root] = false
		tree.children[new_root][0] = old_root
		tree.root = new_root
		if !split_child(mut tree, new_root, 0) { return false }
	}
	return insert_non_full(mut tree, tree.root, key)
}

fn search_key(tree &BTree, key i64) bool {
	mut node := tree.root
	for {
		mut index := 0
		for index < tree.key_count[node] && key > tree.keys[node][index] { index++ }
		if index < tree.key_count[node] && key == tree.keys[node][index] { return true }
		if tree.leaf[node] { return false }
		node = tree.children[node][index]
	}
}

fn walk_in_order(tree &BTree, operation_count int, mut ordered_sum i64) i64 {
	mut node_stack := [32]int{init: 0}
	mut position_stack := [32]int{init: 0}
	mut depth := 1
	mut index := 0
	mut hash := i64(0)
	node_stack[0] = tree.root
	for depth > 0 {
		top := depth - 1
		node := node_stack[top]
		count := tree.key_count[node]
		if tree.leaf[node] {
			if position_stack[top] == count { depth--; continue }
			value := tree.keys[node][position_stack[top]]
			position_stack[top]++
			hash = (hash * 257 + value + 1000001) % hash_mod
			ordered_sum += i64(operation_count + index + 1) * (value + offset)
			index++
		} else if position_stack[top] > 2 * count {
			depth--
		} else {
			position := position_stack[top]
			position_stack[top]++
			if position % 2 == 0 {
				node_stack[depth] = tree.children[node][position / 2]
				position_stack[depth] = 0
				depth++
			} else {
				value := tree.keys[node][position / 2]
				hash = (hash * 257 + value + 1000001) % hash_mod
				ordered_sum += i64(operation_count + index + 1) * (value + offset)
				index++
			}
		}
	}
	return hash
}

@[export: 'b_tree_benchmark']
pub fn b_tree_benchmark(values &i64, length usize) i64 {
	if length < 2 || length > 1024 { return -1 }
	unsafe {
		if values[0] < 2 || values[0] > 8 || values[1] < 0 || values[1] > max_operations { return -1 }
		operation_count := int(values[1])
		if int(length) != 2 + 2 * operation_count { return -1 }
		mut tree := BTree{ used_nodes: 1, root: 0, min_degree: int(values[0]) }
		tree.leaf[0] = true
		mut key_count := 0
		mut checksum := i64(0)
		for operation in 0 .. operation_count {
			opcode := values[2 + 2 * operation]
			payload := values[3 + 2 * operation]
			mut observed := i64(0)
			if opcode == 0 {
				if payload < -offset || payload > offset || key_count == max_key_count || !insert_key(mut tree, payload) { return -1 }
				key_count++
				observed = 1
			} else if opcode == 1 {
				if payload < -offset || payload > offset { return -1 }
				if search_key(tree, payload) { observed = 1 }
			} else if opcode == 2 {
				if payload != 0 { return -1 }
				mut ignored_sum := i64(0)
				observed = walk_in_order(tree, 0, mut ignored_sum)
			} else { return -1 }
			checksum += i64(operation + 1) * (observed + offset)
		}
		walk_in_order(tree, operation_count, mut checksum)
		return checksum
	}
}
