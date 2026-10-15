package b_tree

import "core:c"

MAX_NODE_COUNT :: 257
MAX_NODE_KEYS :: 15
MAX_NODE_CHILDREN :: 16
MAX_KEY_COUNT :: 256
MAX_OPERATIONS :: 511
OFFSET :: i64(1_000_000)
HASH_MOD :: i64(1_000_000_007)

BTree :: struct {
	keys: [MAX_NODE_COUNT][MAX_NODE_KEYS]i64,
	children: [MAX_NODE_COUNT][MAX_NODE_CHILDREN]int,
	key_count: [MAX_NODE_COUNT]int,
	leaf: [MAX_NODE_COUNT]bool,
	used_nodes: int,
	root: int,
	min_degree: int,
}

split_child :: proc(tree: ^BTree, parent, child_index: int) -> bool {
	if tree.used_nodes >= MAX_NODE_COUNT do return false
	child := tree.children[parent][child_index]
	degree := tree.min_degree
	sibling := tree.used_nodes
	tree.used_nodes += 1
	tree.leaf[sibling] = tree.leaf[child]
	tree.key_count[sibling] = degree - 1
	for i := 0; i < degree - 1; i += 1 { tree.keys[sibling][i] = tree.keys[child][degree + i] }
	if !tree.leaf[child] {
		for i := 0; i < degree; i += 1 { tree.children[sibling][i] = tree.children[child][degree + i] }
	}
	parent_count := tree.key_count[parent]
	for i := parent_count + 1; i > child_index + 1; i -= 1 { tree.children[parent][i] = tree.children[parent][i - 1] }
	tree.children[parent][child_index + 1] = sibling
	for i := parent_count; i > child_index; i -= 1 { tree.keys[parent][i] = tree.keys[parent][i - 1] }
	tree.keys[parent][child_index] = tree.keys[child][degree - 1]
	tree.key_count[child] = degree - 1
	tree.key_count[parent] = parent_count + 1
	return true
}

insert_non_full :: proc(tree: ^BTree, node: int, key: i64) -> bool {
	index := tree.key_count[node]
	if tree.leaf[node] {
		for index > 0 && key <= tree.keys[node][index - 1] {
			tree.keys[node][index] = tree.keys[node][index - 1]
			index -= 1
		}
		tree.keys[node][index] = key
		tree.key_count[node] += 1
		return true
	}
	for index > 0 && key <= tree.keys[node][index - 1] { index -= 1 }
	child := tree.children[node][index]
	if tree.key_count[child] == 2 * tree.min_degree - 1 {
		if !split_child(tree, node, index) do return false
		if tree.keys[node][index] < key { index += 1 }
	}
	return insert_non_full(tree, tree.children[node][index], key)
}

insert_key :: proc(tree: ^BTree, key: i64) -> bool {
	if tree.key_count[tree.root] == 2 * tree.min_degree - 1 {
		if tree.used_nodes + 2 > MAX_NODE_COUNT do return false
		old_root := tree.root
		new_root := tree.used_nodes
		tree.used_nodes += 1
		tree.leaf[new_root] = false
		tree.children[new_root][0] = old_root
		tree.root = new_root
		if !split_child(tree, new_root, 0) do return false
	}
	return insert_non_full(tree, tree.root, key)
}

search_key :: proc(tree: ^BTree, key: i64) -> bool {
	node := tree.root
	for {
		index := 0
		for index < tree.key_count[node] && key > tree.keys[node][index] { index += 1 }
		if index < tree.key_count[node] && key == tree.keys[node][index] do return true
		if tree.leaf[node] do return false
		node = tree.children[node][index]
	}
}

walk_in_order :: proc(tree: ^BTree, operation_count: int, ordered_sum: ^i64) -> i64 {
	node_stack: [32]int
	position_stack: [32]int
	depth := 1
	index := 0
	hash := i64(0)
	node_stack[0] = tree.root
	position_stack[0] = 0
	for depth > 0 {
		top := depth - 1
		node := node_stack[top]
		count := tree.key_count[node]
		if tree.leaf[node] {
			if position_stack[top] == count { depth -= 1; continue }
			value := tree.keys[node][position_stack[top]]
			position_stack[top] += 1
			hash = (hash * 257 + value + 1_000_001) % HASH_MOD
			if ordered_sum != nil { ordered_sum^ += i64(operation_count + index + 1) * (value + OFFSET) }
			index += 1
		} else if position_stack[top] > 2 * count {
			depth -= 1
		} else {
			position := position_stack[top]
			position_stack[top] += 1
			if position % 2 == 0 {
				node_stack[depth] = tree.children[node][position / 2]
				position_stack[depth] = 0
				depth += 1
			} else {
				value := tree.keys[node][position / 2]
				hash = (hash * 257 + value + 1_000_001) % HASH_MOD
				if ordered_sum != nil { ordered_sum^ += i64(operation_count + index + 1) * (value + OFFSET) }
				index += 1
			}
		}
	}
	return hash
}

@(export)
b_tree_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 1024 do return -1
	if values[0] < 2 || values[0] > 8 || values[1] < 0 || values[1] > MAX_OPERATIONS do return -1
	operation_count := int(values[1])
	if int(length) != 2 + 2 * operation_count do return -1
	tree := BTree{}
	tree.used_nodes = 1
	tree.root = 0
	tree.min_degree = int(values[0])
	tree.leaf[0] = true
	key_count := 0
	checksum := i64(0)
	for operation := 0; operation < operation_count; operation += 1 {
		opcode := values[2 + 2 * operation]
		payload := values[3 + 2 * operation]
		observed := i64(0)
		if opcode == 0 {
			if payload < -OFFSET || payload > OFFSET || key_count == MAX_KEY_COUNT || !insert_key(&tree, payload) do return -1
			key_count += 1
			observed = 1
		} else if opcode == 1 {
			if payload < -OFFSET || payload > OFFSET do return -1
			if search_key(&tree, payload) { observed = 1 }
		} else if opcode == 2 {
			if payload != 0 do return -1
			observed = walk_in_order(&tree, 0, nil)
		} else do return -1
		checksum += i64(operation + 1) * (observed + OFFSET)
	}
	walk_in_order(&tree, operation_count, &checksum)
	return checksum
}
