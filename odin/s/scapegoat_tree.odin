package scapegoat_tree

import "core:c"

MAX_OPERATIONS :: 64
MAX_LIVE_KEYS :: 32
MAX_INPUT_LENGTH :: 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH :: MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES :: 8 * (2 + MAX_OPERATIONS + MAX_LIVE_KEYS)

Node :: struct { key: i64, left, right: int, active: bool }
Tree :: struct { nodes: [MAX_LIVE_KEYS]Node, root, size, max_size: int }

subtree_size :: proc "contextless" (tree: ^Tree, root: int) -> int {
	if root < 0 do return 0
	return 1 + subtree_size(tree, tree.nodes[root].left) + subtree_size(tree, tree.nodes[root].right)
}

alpha_height :: proc "contextless" (tree: ^Tree, root: int) -> int {
	size := subtree_size(tree, root)
	height := 0
	for size > 1 { size >>= 1; height += 1 }
	return height
}

flatten :: proc "contextless" (tree: ^Tree, root: int, order: [^]int, length: ^int) {
	if root < 0 do return
	flatten(tree, tree.nodes[root].left, order, length)
	order[length^] = root
	length^ += 1
	flatten(tree, tree.nodes[root].right, order, length)
}

rebuild :: proc "contextless" (tree: ^Tree, order: [^]int, start, end: int) -> int {
	if start >= end do return -1
	pivot := (start + end) / 2
	root := order[pivot]
	tree.nodes[root].left = rebuild(tree, order, start, pivot)
	tree.nodes[root].right = rebuild(tree, order, pivot+1, end)
	return root
}

find_key :: proc "contextless" (tree: ^Tree, root_value: int, key: i64) -> bool {
	root := root_value
	for root >= 0 {
		if tree.nodes[root].key == key do return true
		if key < tree.nodes[root].key { root = tree.nodes[root].left }
		else { root = tree.nodes[root].right }
	}
	return false
}

allocate_node :: proc "contextless" (tree: ^Tree, key: i64) -> int {
	for index := 0; index < MAX_LIVE_KEYS; index += 1 {
		if !tree.nodes[index].active {
			tree.nodes[index] = Node{key, -1, -1, true}
			return index
		}
	}
	return -1
}

insert_key :: proc "contextless" (tree: ^Tree, key: i64) -> bool {
	if tree.root < 0 {
		tree.root = allocate_node(tree, key)
		if tree.root < 0 do return false
		tree.size += 1
		tree.max_size = max(tree.max_size, tree.size)
		return true
	}
	path: [MAX_LIVE_KEYS]int
	path_length := 0
	current := tree.root
	for {
		path[path_length] = current
		path_length += 1
		if tree.nodes[current].key == key do return false
		if key < tree.nodes[current].key {
			if tree.nodes[current].left < 0 {
				tree.nodes[current].left = allocate_node(tree, key)
				break
			}
			current = tree.nodes[current].left
		} else {
			if tree.nodes[current].right < 0 {
				tree.nodes[current].right = allocate_node(tree, key)
				break
			}
			current = tree.nodes[current].right
		}
	}
	tree.size += 1
	tree.max_size = max(tree.max_size, tree.size)
	if path_length > alpha_height(tree, tree.root) {
		depth := 1
		scapegoat := -1
		parent := -1
		for path_length > 0 {
			path_length -= 1
			candidate := path[path_length]
			if depth > alpha_height(tree, candidate) {
				scapegoat = candidate
				if path_length > 0 { path_length -= 1; parent = path[path_length] }
				break
			}
			depth += 1
		}
		order: [MAX_LIVE_KEYS]int
		order_length := 0
		flatten(tree, scapegoat, &order[0], &order_length)
		rebuilt := rebuild(tree, &order[0], 0, order_length)
		if parent < 0 { tree.root = rebuilt }
		else if tree.nodes[parent].key < tree.nodes[rebuilt].key { tree.nodes[parent].right = rebuilt }
		else { tree.nodes[parent].left = rebuilt }
	}
	return true
}

delete_key :: proc "contextless" (tree: ^Tree, key: i64) -> bool {
	parent := -1
	node := tree.root
	for node >= 0 && tree.nodes[node].key != key {
		parent = node
		if key < tree.nodes[node].key { node = tree.nodes[node].left }
		else { node = tree.nodes[node].right }
	}
	if node < 0 do return false
	left := tree.nodes[node].left
	right := tree.nodes[node].right
	if left >= 0 && right >= 0 {
		predecessor_parent := node
		predecessor := left
		for tree.nodes[predecessor].right >= 0 {
			predecessor_parent = predecessor
			predecessor = tree.nodes[predecessor].right
		}
		tree.nodes[node].key = tree.nodes[predecessor].key
		replacement := tree.nodes[predecessor].left
		if predecessor_parent == node { tree.nodes[node].left = replacement }
		else { tree.nodes[predecessor_parent].right = replacement }
		tree.nodes[predecessor].active = false
		tree.nodes[predecessor].left = -1
		tree.nodes[predecessor].right = -1
	} else {
		replacement := left
		if replacement < 0 { replacement = right }
		if parent < 0 { tree.root = replacement }
		else if tree.nodes[parent].left == node { tree.nodes[parent].left = replacement }
		else { tree.nodes[parent].right = replacement }
		tree.nodes[node].active = false
		tree.nodes[node].left = -1
		tree.nodes[node].right = -1
	}
	tree.size -= 1
	if tree.root >= 0 && 2 * tree.size < tree.max_size {
		order: [MAX_LIVE_KEYS]int
		order_length := 0
		flatten(tree, tree.root, &order[0], &order_length)
		tree.root = rebuild(tree, &order[0], 0, order_length)
		tree.max_size = tree.size
	}
	return true
}

root_weight_balanced :: proc "contextless" (tree: ^Tree) -> bool {
	if tree.root < 0 do return true
	total := subtree_size(tree, tree.root)
	return 2 * subtree_size(tree, tree.nodes[tree.root].left) <= total &&
		2 * subtree_size(tree, tree.nodes[tree.root].right) <= total
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(byte*8)) }
}

@(export)
scapegoat_tree :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
		capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
	operation_count := int(input[0])
	if int(length) != 1 + 2 * operation_count do return -1

	active_keys: [MAX_LIVE_KEYS]i64 = {}
	active_count := 0
	for operation := 0; operation < operation_count; operation += 1 {
		offset := 1 + 2 * operation
		opcode := input[offset]
		key := input[offset+1]
		if key < -2147483648 || key > 2147483647 || opcode < 0 || opcode > 6 do return -1
		if opcode >= 3 && key != 0 do return -1
		if opcode == 0 {
			present := false
			for i := 0; i < active_count; i += 1 { if active_keys[i] == key { present = true } }
			if !present {
				if active_count == MAX_LIVE_KEYS do return -1
				active_keys[active_count] = key
				active_count += 1
			}
		} else if opcode == 2 {
			for i := 0; i < active_count; i += 1 {
				if active_keys[i] == key {
					for j := i; j+1 < active_count; j += 1 { active_keys[j] = active_keys[j+1] }
					active_count -= 1
					break
				}
			}
		} else if opcode == 6 { active_count = 0 }
	}

	tree: Tree = {}
	tree.root = -1
	for index := 0; index < MAX_LIVE_KEYS; index += 1 { tree.nodes[index].left = -1; tree.nodes[index].right = -1 }
	results: [MAX_OPERATIONS]i64 = {}
	for operation := 0; operation < operation_count; operation += 1 {
		offset := 1 + 2 * operation
		opcode := input[offset]
		key := input[offset+1]
		if opcode == 0 { results[operation] = 0; if insert_key(&tree, key) { results[operation] = 1 } }
		else if opcode == 1 { results[operation] = 0; if find_key(&tree, tree.root, key) { results[operation] = 1 } }
		else if opcode == 2 { results[operation] = 0; if delete_key(&tree, key) { results[operation] = 1 } }
		else if opcode == 3 { results[operation] = i64(tree.size) }
		else if opcode == 4 { results[operation] = i64(tree.max_size) }
		else if opcode == 5 { results[operation] = 0; if root_weight_balanced(&tree) { results[operation] = 1 } }
		else {
			for index := 0; index < MAX_LIVE_KEYS; index += 1 {
				tree.nodes[index].active = false
				tree.nodes[index].left = -1
				tree.nodes[index].right = -1
			}
			tree.root = -1
			tree.size = 0
			tree.max_size = 0
			results[operation] = -2
		}
	}

	output_bytes := (2 + operation_count + tree.size) * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	put_i64_le(&staged[0], 0, i64(operation_count))
	for operation := 0; operation < operation_count; operation += 1 { put_i64_le(&staged[0], (1+operation)*8, results[operation]) }
	put_i64_le(&staged[0], (1+operation_count)*8, i64(tree.size))
	order: [MAX_LIVE_KEYS]int
	order_length := 0
	flatten(&tree, tree.root, &order[0], &order_length)
	for i := 0; i < order_length; i += 1 { put_i64_le(&staged[0], (2+operation_count+i)*8, tree.nodes[order[i]].key) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
