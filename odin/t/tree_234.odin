package tree_234

import core:c

MAX_OPS :: 128
MAX_NODES :: 2049
MAX_OUTPUT_WORDS :: 130

Node :: struct {
	keys: [3]i64,
	children: [4]int,
	key_count: int,
	leaf: bool,
}
Tree :: struct {
	nodes: [MAX_NODES]Node,
	node_count: int,
	root: int,
	final_keys: [MAX_OPS]i64,
	final_count: int,
}

new_node :: proc "contextless" (tree: ^Tree, leaf: bool) -> int {
	index := tree.node_count
	tree.node_count += 1
	tree.nodes[index].key_count = 0
	tree.nodes[index].leaf = leaf
	for i := 0; i < 4; i += 1 { tree.nodes[index].children[i] = -1 }
	return index
}
contains :: proc "contextless" (tree: ^Tree, node_index: int, key: i64) -> bool {
	if node_index < 0 do return false
	node := tree.nodes[node_index]
	i := 0
	for i < node.key_count && key > node.keys[i] { i += 1 }
	if i < node.key_count && key == node.keys[i] do return true
	if node.leaf do return false
	return contains(tree, node.children[i], key)
}
split_child :: proc "contextless" (tree: ^Tree, parent_index, child_position: int) {
	child_index := tree.nodes[parent_index].children[child_position]
	right_index := new_node(tree, tree.nodes[child_index].leaf)
	middle := tree.nodes[child_index].keys[1]
	tree.nodes[right_index].key_count = 1
	tree.nodes[right_index].keys[0] = tree.nodes[child_index].keys[2]
	if !tree.nodes[child_index].leaf {
		tree.nodes[right_index].children[0] = tree.nodes[child_index].children[2]
		tree.nodes[right_index].children[1] = tree.nodes[child_index].children[3]
	}
	tree.nodes[child_index].key_count = 1
	count := tree.nodes[parent_index].key_count
	for i := count; i > child_position; i -= 1 { tree.nodes[parent_index].keys[i] = tree.nodes[parent_index].keys[i-1] }
	for i := count+1; i > child_position+1; i -= 1 { tree.nodes[parent_index].children[i] = tree.nodes[parent_index].children[i-1] }
	tree.nodes[parent_index].keys[child_position] = middle
	tree.nodes[parent_index].children[child_position+1] = right_index
	tree.nodes[parent_index].key_count += 1
}
insert_nonfull :: proc "contextless" (tree: ^Tree, node_index: int, key: i64) {
	i := tree.nodes[node_index].key_count - 1
	if tree.nodes[node_index].leaf {
		for i >= 0 && key < tree.nodes[node_index].keys[i] {
			tree.nodes[node_index].keys[i+1] = tree.nodes[node_index].keys[i]
			i -= 1
		}
		tree.nodes[node_index].keys[i+1] = key
		tree.nodes[node_index].key_count += 1
		return
	}
	for i >= 0 && key < tree.nodes[node_index].keys[i] { i -= 1 }
	i += 1
	if tree.nodes[tree.nodes[node_index].children[i]].key_count == 3 {
		split_child(tree, node_index, i)
		if key > tree.nodes[node_index].keys[i] { i += 1 }
	}
	insert_nonfull(tree, tree.nodes[node_index].children[i], key)
}
insert_key :: proc "contextless" (tree: ^Tree, key: i64) {
	if contains(tree, tree.root, key) do return
	if tree.root < 0 {
		tree.root = new_node(tree, true)
		tree.nodes[tree.root].keys[0] = key
		tree.nodes[tree.root].key_count = 1
		return
	}
	if tree.nodes[tree.root].key_count == 3 {
		old_root := tree.root
		new_root := new_node(tree, false)
		tree.nodes[new_root].children[0] = old_root
		tree.root = new_root
		split_child(tree, new_root, 0)
	}
	insert_nonfull(tree, tree.root, key)
}
find_key :: proc "contextless" (node: Node, key: i64) -> int {
	i := 0
	for i < node.key_count && node.keys[i] < key { i += 1 }
	if i < node.key_count && node.keys[i] == key do return i
	return -1
}
predecessor :: proc "contextless" (tree: ^Tree, node_index: int) -> i64 {
	index := node_index
	for !tree.nodes[index].leaf { index = tree.nodes[index].children[tree.nodes[index].key_count] }
	return tree.nodes[index].keys[tree.nodes[index].key_count-1]
}
successor :: proc "contextless" (tree: ^Tree, node_index: int) -> i64 {
	index := node_index
	for !tree.nodes[index].leaf { index = tree.nodes[index].children[0] }
	return tree.nodes[index].keys[0]
}
merge_children :: proc "contextless" (tree: ^Tree, parent_index, key_index: int) -> int {
	left_index := tree.nodes[parent_index].children[key_index]
	right_index := tree.nodes[parent_index].children[key_index+1]
	left_count := tree.nodes[left_index].key_count
	tree.nodes[left_index].keys[left_count] = tree.nodes[parent_index].keys[key_index]
	for i := 0; i < tree.nodes[right_index].key_count; i += 1 {
		tree.nodes[left_index].keys[left_count+1+i] = tree.nodes[right_index].keys[i]
	}
	if !tree.nodes[left_index].leaf {
		for i := 0; i <= tree.nodes[right_index].key_count; i += 1 {
			tree.nodes[left_index].children[left_count+1+i] = tree.nodes[right_index].children[i]
		}
	}
	tree.nodes[left_index].key_count = left_count+1+tree.nodes[right_index].key_count
	parent_count := tree.nodes[parent_index].key_count
	for i := key_index; i < parent_count-1; i += 1 { tree.nodes[parent_index].keys[i] = tree.nodes[parent_index].keys[i+1] }
	for i := key_index+1; i < parent_count; i += 1 { tree.nodes[parent_index].children[i] = tree.nodes[parent_index].children[i+1] }
	tree.nodes[parent_index].key_count -= 1
	return left_index
}
borrow_previous :: proc "contextless" (tree: ^Tree, parent_index, child_index: int) {
	child := tree.nodes[parent_index].children[child_index]
	sibling := tree.nodes[parent_index].children[child_index-1]
	count := tree.nodes[child].key_count
	for i := count; i > 0; i -= 1 { tree.nodes[child].keys[i] = tree.nodes[child].keys[i-1] }
	if !tree.nodes[child].leaf {
		for i := count+1; i > 0; i -= 1 { tree.nodes[child].children[i] = tree.nodes[child].children[i-1] }
		tree.nodes[child].children[0] = tree.nodes[sibling].children[tree.nodes[sibling].key_count]
	}
	tree.nodes[child].keys[0] = tree.nodes[parent_index].keys[child_index-1]
	last := tree.nodes[sibling].key_count-1
	tree.nodes[parent_index].keys[child_index-1] = tree.nodes[sibling].keys[last]
	tree.nodes[child].key_count += 1
	tree.nodes[sibling].key_count -= 1
}
borrow_next :: proc "contextless" (tree: ^Tree, parent_index, child_index: int) {
	child := tree.nodes[parent_index].children[child_index]
	sibling := tree.nodes[parent_index].children[child_index+1]
	count := tree.nodes[child].key_count
	tree.nodes[child].keys[count] = tree.nodes[parent_index].keys[child_index]
	if !tree.nodes[child].leaf { tree.nodes[child].children[count+1] = tree.nodes[sibling].children[0] }
	tree.nodes[parent_index].keys[child_index] = tree.nodes[sibling].keys[0]
	sibling_count := tree.nodes[sibling].key_count
	for i := 0; i < sibling_count-1; i += 1 { tree.nodes[sibling].keys[i] = tree.nodes[sibling].keys[i+1] }
	if !tree.nodes[sibling].leaf {
		for i := 0; i < sibling_count; i += 1 { tree.nodes[sibling].children[i] = tree.nodes[sibling].children[i+1] }
	}
	tree.nodes[child].key_count += 1
	tree.nodes[sibling].key_count -= 1
}
remove_from_node :: proc "contextless" (tree: ^Tree, node_index: int, key: i64) {
	key_index := find_key(tree.nodes[node_index], key)
	if key_index >= 0 {
		if tree.nodes[node_index].leaf {
			count := tree.nodes[node_index].key_count
			for i := key_index; i < count-1; i += 1 { tree.nodes[node_index].keys[i] = tree.nodes[node_index].keys[i+1] }
			tree.nodes[node_index].key_count -= 1
			return
		}
		left := tree.nodes[node_index].children[key_index]
		right := tree.nodes[node_index].children[key_index+1]
		if tree.nodes[left].key_count >= 2 {
			replacement := predecessor(tree, left)
			tree.nodes[node_index].keys[key_index] = replacement
			remove_from_node(tree, left, replacement)
		} else if tree.nodes[right].key_count >= 2 {
			replacement := successor(tree, right)
			tree.nodes[node_index].keys[key_index] = replacement
			remove_from_node(tree, right, replacement)
		} else {
			merged := merge_children(tree, node_index, key_index)
			remove_from_node(tree, merged, key)
		}
		return
	}
	if tree.nodes[node_index].leaf do return
	child_index := 0
	for child_index < tree.nodes[node_index].key_count && key > tree.nodes[node_index].keys[child_index] { child_index += 1 }
	child := tree.nodes[node_index].children[child_index]
	if tree.nodes[child].key_count == 1 {
		if child_index > 0 && tree.nodes[tree.nodes[node_index].children[child_index-1]].key_count >= 2 {
			borrow_previous(tree, node_index, child_index)
		} else if child_index < tree.nodes[node_index].key_count && tree.nodes[tree.nodes[node_index].children[child_index+1]].key_count >= 2 {
			borrow_next(tree, node_index, child_index)
		} else if child_index < tree.nodes[node_index].key_count {
			child = merge_children(tree, node_index, child_index)
		} else {
			child = merge_children(tree, node_index, child_index-1)
		}
	}
	remove_from_node(tree, child, key)
}
remove_key :: proc "contextless" (tree: ^Tree, key: i64) -> i64 {
	if !contains(tree, tree.root, key) do return 0
	remove_from_node(tree, tree.root, key)
	if tree.root >= 0 && tree.nodes[tree.root].key_count == 0 {
		old_root := tree.root
		if tree.nodes[old_root].leaf { tree.root = -1 } else { tree.root = tree.nodes[old_root].children[0] }
	}
	return 1
}
traverse :: proc "contextless" (tree: ^Tree, node_index: int) {
	if node_index < 0 do return
	for i := 0; i < tree.nodes[node_index].key_count; i += 1 {
		if !tree.nodes[node_index].leaf { traverse(tree, tree.nodes[node_index].children[i]) }
		tree.final_keys[tree.final_count] = tree.nodes[node_index].keys[i]
		tree.final_count += 1
	}
	if !tree.nodes[node_index].leaf { traverse(tree, tree.nodes[node_index].children[tree.nodes[node_index].key_count]) }
}
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[offset+b] = u8(bits >> (8*b)) }
}

@(export)
tree_234 :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 258 do return -1
	if input[0] < 0 || input[0] > MAX_OPS do return -1
	ops := int(input[0])
	if length != c.size_t(1+2*ops) do return -1
	for i := 0; i < ops; i += 1 { op := input[1+2*i]; if op != 0 && op != 1 do return -1 }
	var tree: Tree
	tree.root = -1
	var remove_results: [MAX_OPS]i64
	remove_count := 0
	for i := 0; i < ops; i += 1 {
		op, key := input[1+2*i], input[2+2*i]
		if op == 0 { insert_key(&tree, key) } else { remove_results[remove_count] = remove_key(&tree, key); remove_count += 1 }
	}
	traverse(&tree, tree.root)
	var words: [MAX_OUTPUT_WORDS]i64
	words[0] = i64(remove_count)
	for i := 0; i < remove_count; i += 1 { words[1+i] = remove_results[i] }
	words[1+remove_count] = i64(tree.final_count)
	for i := 0; i < tree.final_count; i += 1 { words[2+remove_count+i] = tree.final_keys[i] }
	word_count := 2+remove_count+tree.final_count
	output_bytes := word_count*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < word_count; i += 1 { put_i64(output, i*8, words[i]) }
	return i64(output_bytes)
}
