package btree_unique_key_set

import "core:c"

MIN_DEGREE :: 255
MAX_NODE_KEYS :: 2*MIN_DEGREE-1
MAX_NODE_COUNT :: 32
MAX_INSERTS :: 2048
MAX_QUERIES :: 1024
MAX_DELETES :: 1024
MAX_OUTPUT_VALUES :: 2+MAX_QUERIES+MAX_INSERTS

BTree :: struct {
	keys: [MAX_NODE_COUNT][MAX_NODE_KEYS]i32,
	children: [MAX_NODE_COUNT][MAX_NODE_KEYS+1]int,
	key_count: [MAX_NODE_COUNT]int,
	leaf: [MAX_NODE_COUNT]bool,
	used_nodes: int,
	root: int,
}

new_tree :: proc() -> BTree {
	mut tree: BTree
	tree.used_nodes = 1
	tree.leaf[0] = true
	return tree
}

search_key :: proc(tree: ^BTree, key: i32) -> bool {
	node := tree.root
	for {
		index := 0
		for index < tree.key_count[node] && key > tree.keys[node][index] { index += 1 }
		if index < tree.key_count[node] && key == tree.keys[node][index] { return true }
		if tree.leaf[node] { return false }
		node = tree.children[node][index]
	}
}

split_child :: proc(tree: ^BTree, parent, child_index: int) -> bool {
	if tree.used_nodes >= MAX_NODE_COUNT { return false }
	child := tree.children[parent][child_index]
	sibling := tree.used_nodes
	tree.used_nodes += 1
	tree.leaf[sibling] = tree.leaf[child]
	for i := 0; i < MIN_DEGREE-1; i += 1 { tree.keys[sibling][i] = tree.keys[child][i+MIN_DEGREE] }
	if !tree.leaf[child] {
		for i := 0; i < MIN_DEGREE; i += 1 { tree.children[sibling][i] = tree.children[child][i+MIN_DEGREE] }
	}
	tree.key_count[sibling] = MIN_DEGREE-1
	parent_count := tree.key_count[parent]
	for i := parent_count+1; i > child_index+1; i -= 1 { tree.children[parent][i] = tree.children[parent][i-1] }
	tree.children[parent][child_index+1] = sibling
	for i := parent_count; i > child_index; i -= 1 { tree.keys[parent][i] = tree.keys[parent][i-1] }
	tree.keys[parent][child_index] = tree.keys[child][MIN_DEGREE-1]
	tree.key_count[child] = MIN_DEGREE-1
	tree.key_count[parent] = parent_count+1
	return true
}

insert_non_full :: proc(tree: ^BTree, node: int, key: i32) -> bool {
	index := tree.key_count[node]
	if tree.leaf[node] {
		for index > 0 && key < tree.keys[node][index-1] {
			tree.keys[node][index] = tree.keys[node][index-1]
			index -= 1
		}
		tree.keys[node][index] = key
		tree.key_count[node] += 1
		return true
	}
	for index > 0 && key < tree.keys[node][index-1] { index -= 1 }
	if tree.key_count[tree.children[node][index]] == MAX_NODE_KEYS {
		if !split_child(tree, node, index) { return false }
		if key > tree.keys[node][index] { index += 1 }
	}
	return insert_non_full(tree, tree.children[node][index], key)
}

insert_key :: proc(tree: ^BTree, key: i32) -> bool {
	if tree.key_count[tree.root] == MAX_NODE_KEYS {
		if tree.used_nodes >= MAX_NODE_COUNT { return false }
		old_root := tree.root
		root := tree.used_nodes
		tree.used_nodes += 1
		tree.leaf[root] = false
		tree.children[root][0] = old_root
		tree.root = root
		if !split_child(tree, root, 0) { return false }
	}
	return insert_non_full(tree, tree.root, key)
}

predecessor :: proc(tree: ^BTree, start: int) -> i32 {
	node := start
	for !tree.leaf[node] { node = tree.children[node][tree.key_count[node]] }
	return tree.keys[node][tree.key_count[node]-1]
}

successor :: proc(tree: ^BTree, start: int) -> i32 {
	node := start
	for !tree.leaf[node] { node = tree.children[node][0] }
	return tree.keys[node][0]
}

merge_children :: proc(tree: ^BTree, parent, index: int) {
	left := tree.children[parent][index]
	right := tree.children[parent][index+1]
	left_count := tree.key_count[left]
	tree.keys[left][left_count] = tree.keys[parent][index]
	left_count += 1
	for i := 0; i < tree.key_count[right]; i += 1 { tree.keys[left][left_count+i] = tree.keys[right][i] }
	if !tree.leaf[left] {
		for i := 0; i < tree.key_count[right]+1; i += 1 { tree.children[left][left_count+i] = tree.children[right][i] }
	}
	tree.key_count[left] = left_count+tree.key_count[right]
	parent_count := tree.key_count[parent]
	for i := index+1; i < parent_count; i += 1 { tree.keys[parent][i-1] = tree.keys[parent][i] }
	for i := index+2; i <= parent_count; i += 1 { tree.children[parent][i-1] = tree.children[parent][i] }
	tree.key_count[parent] -= 1
}

borrow_previous :: proc(tree: ^BTree, parent, index: int) {
	child := tree.children[parent][index]
	sibling := tree.children[parent][index-1]
	count := tree.key_count[child]
	for i := count; i > 0; i -= 1 { tree.keys[child][i] = tree.keys[child][i-1] }
	if !tree.leaf[child] {
		for i := count+1; i > 0; i -= 1 { tree.children[child][i] = tree.children[child][i-1] }
	}
	tree.keys[child][0] = tree.keys[parent][index-1]
	if !tree.leaf[child] { tree.children[child][0] = tree.children[sibling][tree.key_count[sibling]] }
	tree.keys[parent][index-1] = tree.keys[sibling][tree.key_count[sibling]-1]
	tree.key_count[child] += 1
	tree.key_count[sibling] -= 1
}

borrow_next :: proc(tree: ^BTree, parent, index: int) {
	child := tree.children[parent][index]
	sibling := tree.children[parent][index+1]
	child_count := tree.key_count[child]
	sibling_count := tree.key_count[sibling]
	tree.keys[child][child_count] = tree.keys[parent][index]
	if !tree.leaf[child] { tree.children[child][child_count+1] = tree.children[sibling][0] }
	tree.keys[parent][index] = tree.keys[sibling][0]
	for i := 1; i < sibling_count; i += 1 { tree.keys[sibling][i-1] = tree.keys[sibling][i] }
	if !tree.leaf[sibling] {
		for i := 1; i <= sibling_count; i += 1 { tree.children[sibling][i-1] = tree.children[sibling][i] }
	}
	tree.key_count[child] += 1
	tree.key_count[sibling] -= 1
}

fill_child :: proc(tree: ^BTree, parent, index: int) {
	if index > 0 && tree.key_count[tree.children[parent][index-1]] >= MIN_DEGREE {
		borrow_previous(tree, parent, index)
	} else if index < tree.key_count[parent] && tree.key_count[tree.children[parent][index+1]] >= MIN_DEGREE {
		borrow_next(tree, parent, index)
	} else {
		merge_children(tree, parent, if index < tree.key_count[parent] then index else index-1)
	}
}

delete_from :: proc(tree: ^BTree, node: int, key: i32) -> bool {
	index := 0
	for index < tree.key_count[node] && tree.keys[node][index] < key { index += 1 }
	if index < tree.key_count[node] && tree.keys[node][index] == key {
		if tree.leaf[node] {
			for i := index+1; i < tree.key_count[node]; i += 1 { tree.keys[node][i-1] = tree.keys[node][i] }
			tree.key_count[node] -= 1
		} else {
			left := tree.children[node][index]
			right := tree.children[node][index+1]
			if tree.key_count[left] >= MIN_DEGREE {
				replacement := predecessor(tree, left)
				tree.keys[node][index] = replacement
				return delete_from(tree, left, replacement)
			}
			if tree.key_count[right] >= MIN_DEGREE {
				replacement := successor(tree, right)
				tree.keys[node][index] = replacement
				return delete_from(tree, right, replacement)
			}
			merge_children(tree, node, index)
			return delete_from(tree, left, key)
		}
		return true
	}
	if tree.leaf[node] { return false }
	was_last := index == tree.key_count[node]
	if tree.key_count[tree.children[node][index]] < MIN_DEGREE { fill_child(tree, node, index) }
	if was_last && index > tree.key_count[node] { index -= 1 }
	return delete_from(tree, tree.children[node][index], key)
}

delete_key :: proc(tree: ^BTree, key: i32) -> bool {
	if !delete_from(tree, tree.root, key) { return false }
	if tree.key_count[tree.root] == 0 && !tree.leaf[tree.root] { tree.root = tree.children[tree.root][0] }
	return true
}

traverse :: proc(tree: ^BTree, node: int, result: [^]i64, length: ^int) {
	for i := 0; i < tree.key_count[node]; i += 1 {
		if !tree.leaf[node] { traverse(tree, tree.children[node][i], result, length) }
	result[length^] = i64(tree.keys[node][i])
	length^ += 1
	}
	if !tree.leaf[node] { traverse(tree, tree.children[node][tree.key_count[node]], result, length) }
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
btree_unique_key_set :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 4096 do return -1
	if input[0] < 0 || input[0] > MAX_INSERTS do return -1
	insert_count := int(input[0])
	query_offset := 1+insert_count
	if query_offset >= int(length) || input[query_offset] < 0 || input[query_offset] > MAX_QUERIES do return -1
	query_count := int(input[query_offset])
	delete_count_offset := query_offset+1+query_count
	if delete_count_offset >= int(length) || input[delete_count_offset] < 0 || input[delete_count_offset] > MAX_DELETES do return -1
	delete_count := int(input[delete_count_offset])
	if int(length) != 3+insert_count+query_count+delete_count do return -1

	mut tree := new_tree()
	for i := 0; i < insert_count; i += 1 {
		raw := input[1+i]
		if raw < -2147483648 || raw > 2147483647 do return -1
		key := i32(raw)
		if search_key(&tree, key) || !insert_key(&tree, key) do return -1
	}
	var result: [MAX_OUTPUT_VALUES]i64
	result_length := 0
	result[result_length] = i64(query_count)
	result_length += 1
	query_start := query_offset+1
	for i := 0; i < query_count; i += 1 {
		raw := input[query_start+i]
		if raw < -2147483648 || raw > 2147483647 do return -1
		result[result_length] = 0
		if search_key(&tree, i32(raw)) { result[result_length] = 1 }
		result_length += 1
	}
	delete_start := delete_count_offset+1
	for i := 0; i < delete_count; i += 1 {
		raw := input[delete_start+i]
		if raw < -2147483648 || raw > 2147483647 || !delete_key(&tree, i32(raw)) do return -1
	}
	count_slot := result_length
	result_length += 1
	traverse(&tree, tree.root, &result[0], &result_length)
	result[count_slot] = i64(result_length-count_slot-1)
	output_bytes := result_length*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < result_length; i += 1 { store_i64_le(output, i*8, result[i]) }
	return i64(output_bytes)
}
