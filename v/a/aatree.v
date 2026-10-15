module aatree

const max_operations = 256

struct Node {
	mut:
	key i32
	left i32
	right i32
	level i32
}
struct Tree {
	mut:
	nodes [256]Node
	used int
}

fn node_level(tree &Tree, node i32) i32 {
	if node < 0 { return 0 }
	return tree.nodes[int(node)].level
}
fn contains(tree &Tree, root_input i32, key i32) bool {
	mut root := root_input
	for root >= 0 {
		if key < tree.nodes[int(root)].key { root = tree.nodes[int(root)].left }
		else if key > tree.nodes[int(root)].key { root = tree.nodes[int(root)].right }
		else { return true }
	}
	return false
}
fn skew(mut tree Tree, root i32) i32 {
	if root < 0 { return root }
	left_child := tree.nodes[int(root)].left
	if left_child < 0 || tree.nodes[int(left_child)].level != tree.nodes[int(root)].level { return root }
	tree.nodes[int(root)].left = tree.nodes[int(left_child)].right
	tree.nodes[int(left_child)].right = root
	return left_child
}
fn split(mut tree Tree, root i32) i32 {
	if root < 0 { return root }
	right_child := tree.nodes[int(root)].right
	if right_child < 0 { return root }
	right_right := tree.nodes[int(right_child)].right
	if right_right < 0 || tree.nodes[int(root)].level != tree.nodes[int(right_right)].level { return root }
	tree.nodes[int(root)].right = tree.nodes[int(right_child)].left
	tree.nodes[int(right_child)].left = root
	tree.nodes[int(right_child)].level++
	return right_child
}
fn insert_node(mut tree Tree, root i32, key i32) i32 {
	if root < 0 {
		fresh := tree.used
		tree.used++
		tree.nodes[fresh] = Node{key: key, left: -1, right: -1, level: 1}
		return i32(fresh)
	}
	if key < tree.nodes[int(root)].key {
		child := tree.nodes[int(root)].left
		tree.nodes[int(root)].left = insert_node(mut tree, child, key)
	} else {
		child := tree.nodes[int(root)].right
		tree.nodes[int(root)].right = insert_node(mut tree, child, key)
	}
	return split(mut tree, skew(mut tree, root))
}
fn minimum_node(tree &Tree, root_input i32) i32 {
	mut root := root_input
	for tree.nodes[int(root)].left >= 0 { root = tree.nodes[int(root)].left }
	return root
}
fn maximum_node(tree &Tree, root_input i32) i32 {
	mut root := root_input
	for tree.nodes[int(root)].right >= 0 { root = tree.nodes[int(root)].right }
	return root
}
fn decrease_level(mut tree Tree, root i32) i32 {
	mut new_level := node_level(tree, tree.nodes[int(root)].left)
	right_level := node_level(tree, tree.nodes[int(root)].right)
	if right_level < new_level { new_level = right_level }
	new_level++
	if new_level < tree.nodes[int(root)].level {
		tree.nodes[int(root)].level = new_level
		right_child := tree.nodes[int(root)].right
		if right_child >= 0 && new_level < tree.nodes[int(right_child)].level { tree.nodes[int(right_child)].level = new_level }
	}
	return root
}
fn remove_node(mut tree Tree, root i32, key i32) i32 {
	if key < tree.nodes[int(root)].key {
		child := tree.nodes[int(root)].left
		tree.nodes[int(root)].left = remove_node(mut tree, child, key)
	} else if key > tree.nodes[int(root)].key {
		child := tree.nodes[int(root)].right
		tree.nodes[int(root)].right = remove_node(mut tree, child, key)
	} else if tree.nodes[int(root)].left < 0 && tree.nodes[int(root)].right < 0 {
		return -1
	} else if tree.nodes[int(root)].left < 0 {
		successor := minimum_node(tree, tree.nodes[int(root)].right)
		successor_key := tree.nodes[int(successor)].key
		tree.nodes[int(root)].key = successor_key
		child := tree.nodes[int(root)].right
		tree.nodes[int(root)].right = remove_node(mut tree, child, successor_key)
	} else {
		predecessor := maximum_node(tree, tree.nodes[int(root)].left)
		predecessor_key := tree.nodes[int(predecessor)].key
		tree.nodes[int(root)].key = predecessor_key
		child := tree.nodes[int(root)].left
		tree.nodes[int(root)].left = remove_node(mut tree, child, predecessor_key)
	}
	mut current := skew(mut tree, decrease_level(mut tree, root))
	mut right_child := tree.nodes[int(current)].right
	if right_child >= 0 {
		right_child = skew(mut tree, right_child)
		right_right := tree.nodes[int(right_child)].right
		if right_right >= 0 { tree.nodes[int(right_child)].right = skew(mut tree, right_right) }
		tree.nodes[int(current)].right = right_child
	}
	current = split(mut tree, current)
	right_child = tree.nodes[int(current)].right
	if right_child >= 0 { tree.nodes[int(current)].right = split(mut tree, right_child) }
	return current
}
fn write_i32(mut output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe {
		output[offset] = u8(bits)
		output[offset + 1] = u8(bits >> 8)
		output[offset + 2] = u8(bits >> 16)
		output[offset + 3] = u8(bits >> 24)
	}
}

@[export: 'aatree']
pub fn aatree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 1 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_operations { return -1 }
		operation_count := int(input[0])
		if length != usize(1 + 2 * operation_count) { return -1 }
		output_bytes := 4 * operation_count
		if output_bytes == 0 { return 0 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut tree := Tree{}
		mut root := i32(-1)
		mut size := i32(0)
		for operation in 0 .. operation_count {
			opcode := input[1 + 2 * operation]
			raw_key := input[2 + 2 * operation]
			if opcode < 0 || opcode > 4 { return -1 }
			if opcode <= 2 && (raw_key < -2147483648 || raw_key > 2147483647) { return -1 }
			if opcode >= 3 && raw_key != 0 { return -1 }
			key := i32(raw_key)
			mut answer := i32(0)
			if opcode == 0 {
				if contains(&tree, root, key) { return -1 }
				root = insert_node(mut tree, root, key)
				size++
				answer = size
			} else if opcode == 1 {
				if !contains(&tree, root, key) { return -1 }
				root = remove_node(mut tree, root, key)
				size--
				answer = size
			} else if opcode == 2 {
				if contains(&tree, root, key) { answer = 1 }
			} else if root < 0 { return -1 }
			else if opcode == 3 { answer = tree.nodes[int(minimum_node(&tree, root))].key }
			else { answer = tree.nodes[int(maximum_node(&tree, root))].key }
			write_i32(mut output, operation * 4, answer)
		}
		return i64(output_bytes)
	}
}
