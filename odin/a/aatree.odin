package aatree

import "core:c"

MAX_OPERATIONS :: 256
Node :: struct { key: i32, left: i32, right: i32, level: i32 }
Tree :: struct { nodes: [MAX_OPERATIONS]Node, used: i32 }

node_level :: proc "contextless" (tree: ^Tree, node: i32) -> i32 {
	if node < 0 { return 0 }
	return tree.nodes[node].level
}
contains :: proc "contextless" (tree: ^Tree, root_input: i32, key: i32) -> bool {
	root := root_input
	for root >= 0 {
		if key < tree.nodes[root].key { root = tree.nodes[root].left }
		else if key > tree.nodes[root].key { root = tree.nodes[root].right }
		else { return true }
	}
	return false
}
skew :: proc "contextless" (tree: ^Tree, root: i32) -> i32 {
	if root < 0 { return root }
	left_child := tree.nodes[root].left
	if left_child < 0 || tree.nodes[left_child].level != tree.nodes[root].level { return root }
	tree.nodes[root].left = tree.nodes[left_child].right
	tree.nodes[left_child].right = root
	return left_child
}
split :: proc "contextless" (tree: ^Tree, root: i32) -> i32 {
	if root < 0 { return root }
	right_child := tree.nodes[root].right
	if right_child < 0 { return root }
	right_right := tree.nodes[right_child].right
	if right_right < 0 || tree.nodes[root].level != tree.nodes[right_right].level { return root }
	tree.nodes[root].right = tree.nodes[right_child].left
	tree.nodes[right_child].left = root
	tree.nodes[right_child].level += 1
	return right_child
}
insert_node :: proc "contextless" (tree: ^Tree, root: i32, key: i32) -> i32 {
	if root < 0 {
		fresh := tree.used
		tree.used += 1
		tree.nodes[fresh] = Node{key = key, left = -1, right = -1, level = 1}
		return fresh
	}
	if key < tree.nodes[root].key {
		child := tree.nodes[root].left
		tree.nodes[root].left = insert_node(tree, child, key)
	} else {
		child := tree.nodes[root].right
		tree.nodes[root].right = insert_node(tree, child, key)
	}
	return split(tree, skew(tree, root))
}
minimum_node :: proc "contextless" (tree: ^Tree, root_input: i32) -> i32 {
	root := root_input
	for tree.nodes[root].left >= 0 { root = tree.nodes[root].left }
	return root
}
maximum_node :: proc "contextless" (tree: ^Tree, root_input: i32) -> i32 {
	root := root_input
	for tree.nodes[root].right >= 0 { root = tree.nodes[root].right }
	return root
}
decrease_level :: proc "contextless" (tree: ^Tree, root: i32) -> i32 {
	new_level := min(node_level(tree, tree.nodes[root].left), node_level(tree, tree.nodes[root].right)) + 1
	if new_level < tree.nodes[root].level {
		tree.nodes[root].level = new_level
		right_child := tree.nodes[root].right
		if right_child >= 0 && new_level < tree.nodes[right_child].level { tree.nodes[right_child].level = new_level }
	}
	return root
}
remove_node :: proc "contextless" (tree: ^Tree, root: i32, key: i32) -> i32 {
	if key < tree.nodes[root].key {
		child := tree.nodes[root].left
		tree.nodes[root].left = remove_node(tree, child, key)
	} else if key > tree.nodes[root].key {
		child := tree.nodes[root].right
		tree.nodes[root].right = remove_node(tree, child, key)
	} else if tree.nodes[root].left < 0 && tree.nodes[root].right < 0 {
		return -1
	} else if tree.nodes[root].left < 0 {
		successor := minimum_node(tree, tree.nodes[root].right)
		successor_key := tree.nodes[successor].key
		tree.nodes[root].key = successor_key
		child := tree.nodes[root].right
		tree.nodes[root].right = remove_node(tree, child, successor_key)
	} else {
		predecessor := maximum_node(tree, tree.nodes[root].left)
		predecessor_key := tree.nodes[predecessor].key
		tree.nodes[root].key = predecessor_key
		child := tree.nodes[root].left
		tree.nodes[root].left = remove_node(tree, child, predecessor_key)
	}
	current := skew(tree, decrease_level(tree, root))
	right_child := tree.nodes[current].right
	if right_child >= 0 {
		right_child = skew(tree, right_child)
		right_right := tree.nodes[right_child].right
		if right_right >= 0 { tree.nodes[right_child].right = skew(tree, right_right) }
		tree.nodes[current].right = right_child
	}
	current = split(tree, current)
	right_child = tree.nodes[current].right
	if right_child >= 0 { tree.nodes[current].right = split(tree, right_child) }
	return current
}
write_i32 :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	output[offset] = u8(bits)
	output[offset + 1] = u8(bits >> 8)
	output[offset + 2] = u8(bits >> 16)
	output[offset + 3] = u8(bits >> 24)
}

@(export)
aatree :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
	operation_count := int(input[0])
	if int(length) != 1 + 2 * operation_count do return -1
	output_bytes := 4 * operation_count
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2
	tree := Tree{}
	root := i32(-1)
	size := i32(0)
	for operation := 0; operation < operation_count; operation += 1 {
		opcode := input[1 + 2 * operation]
		raw_key := input[2 + 2 * operation]
		if opcode < 0 || opcode > 4 do return -1
		if opcode <= 2 && (raw_key < i64(-2147483648) || raw_key > i64(2147483647)) do return -1
		if opcode >= 3 && raw_key != 0 do return -1
		key := i32(raw_key)
		answer := i32(0)
		if opcode == 0 {
			if contains(&tree, root, key) do return -1
			root = insert_node(&tree, root, key)
			size += 1
			answer = size
		} else if opcode == 1 {
			if !contains(&tree, root, key) do return -1
			root = remove_node(&tree, root, key)
			size -= 1
			answer = size
		} else if opcode == 2 {
			answer = i32(bool(contains(&tree, root, key)))
		} else if root < 0 {
			return -1
		} else if opcode == 3 {
			answer = tree.nodes[minimum_node(&tree, root)].key
		} else {
			answer = tree.nodes[maximum_node(&tree, root)].key
		}
		write_i32(output, operation * 4, answer)
	}
	return i64(output_bytes)
}
