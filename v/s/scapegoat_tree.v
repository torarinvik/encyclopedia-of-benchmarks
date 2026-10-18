module scapegoat_tree

const max_operations = 64
const max_live_keys = 32
const max_input_length = 1 + 2 * max_operations
const max_parseable_input_length = max_input_length + 1
const max_output_bytes = 8 * (2 + max_operations + max_live_keys)

struct Node {
	mut:
	key i64
	left int
	right int
	active bool
}

struct Tree {
	mut:
	nodes [max_live_keys]Node
	root int
	size int
	max_size int
	order [max_live_keys]int
	order_length int
}

fn subtree_size(tree &Tree, root int) int {
	if root < 0 { return 0 }
	return 1 + subtree_size(tree, tree.nodes[root].left) + subtree_size(tree, tree.nodes[root].right)
}

fn alpha_height(tree &Tree, root int) int {
	mut size := subtree_size(tree, root)
	mut height := 0
	for size > 1 { size >>= 1; height++ }
	return height
}

fn flatten(mut tree Tree, root int) {
	if root < 0 { return }
	flatten(mut tree, tree.nodes[root].left)
	tree.order[tree.order_length] = root
	tree.order_length++
	flatten(mut tree, tree.nodes[root].right)
}

fn rebuild(mut tree Tree, start int, end int) int {
	if start >= end { return -1 }
	pivot := (start + end) / 2
	root := tree.order[pivot]
	tree.nodes[root].left = rebuild(mut tree, start, pivot)
	tree.nodes[root].right = rebuild(mut tree, pivot + 1, end)
	return root
}

fn find_key(tree &Tree, root_value int, key i64) bool {
	mut root := root_value
	for root >= 0 {
		if tree.nodes[root].key == key { return true }
		if key < tree.nodes[root].key { root = tree.nodes[root].left }
		else { root = tree.nodes[root].right }
	}
	return false
}

fn allocate_node(mut tree Tree, key i64) int {
	for index in 0 .. max_live_keys {
		if !tree.nodes[index].active {
			tree.nodes[index] = Node{key: key, left: -1, right: -1, active: true}
			return index
		}
	}
	return -1
}

fn insert_key(mut tree Tree, key i64) bool {
	if tree.root < 0 {
		tree.root = allocate_node(mut tree, key)
		if tree.root < 0 { return false }
		tree.size++
		tree.max_size = max(tree.max_size, tree.size)
		return true
	}
	mut path := [max_live_keys]int{}
	mut path_length := 0
	mut current := tree.root
	for {
		path[path_length] = current
		path_length++
		if tree.nodes[current].key == key { return false }
		if key < tree.nodes[current].key {
			if tree.nodes[current].left < 0 {
				tree.nodes[current].left = allocate_node(mut tree, key)
				break
			}
			current = tree.nodes[current].left
		} else {
			if tree.nodes[current].right < 0 {
				tree.nodes[current].right = allocate_node(mut tree, key)
				break
			}
			current = tree.nodes[current].right
		}
	}
	tree.size++
	tree.max_size = max(tree.max_size, tree.size)
	if path_length > alpha_height(tree, tree.root) {
		mut depth := 1
		mut scapegoat := -1
		mut parent := -1
		for path_length > 0 {
			path_length--
			candidate := path[path_length]
			if depth > alpha_height(tree, candidate) {
				scapegoat = candidate
				if path_length > 0 { path_length--; parent = path[path_length] }
				break
			}
			depth++
		}
		tree.order_length = 0
		flatten(mut tree, scapegoat)
		rebuilt := rebuild(mut tree, 0, tree.order_length)
		if parent < 0 { tree.root = rebuilt }
		else if tree.nodes[parent].key < tree.nodes[rebuilt].key { tree.nodes[parent].right = rebuilt }
		else { tree.nodes[parent].left = rebuilt }
	}
	return true
}

fn delete_key(mut tree Tree, key i64) bool {
	mut parent := -1
	mut node := tree.root
	for node >= 0 && tree.nodes[node].key != key {
		parent = node
		if key < tree.nodes[node].key { node = tree.nodes[node].left }
		else { node = tree.nodes[node].right }
	}
	if node < 0 { return false }
	left := tree.nodes[node].left
	right := tree.nodes[node].right
	if left >= 0 && right >= 0 {
		mut predecessor_parent := node
		mut predecessor := left
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
		replacement := if left >= 0 { left } else { right }
		if parent < 0 { tree.root = replacement }
		else if tree.nodes[parent].left == node { tree.nodes[parent].left = replacement }
		else { tree.nodes[parent].right = replacement }
		tree.nodes[node].active = false
		tree.nodes[node].left = -1
		tree.nodes[node].right = -1
	}
	tree.size--
	if tree.root >= 0 && 2 * tree.size < tree.max_size {
		tree.order_length = 0
		flatten(mut tree, tree.root)
		tree.root = rebuild(mut tree, 0, tree.order_length)
		tree.max_size = tree.size
	}
	return true
}

fn root_weight_balanced(tree &Tree) bool {
	if tree.root < 0 { return true }
	total := subtree_size(tree, tree.root)
	return 2 * subtree_size(tree, tree.nodes[tree.root].left) <= total &&
		2 * subtree_size(tree, tree.nodes[tree.root].right) <= total
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'scapegoat_tree']
pub fn scapegoat_tree(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input_length { return -1 }
		if input[0] < 0 || input[0] > max_operations { return -1 }
		operation_count := int(input[0])
		if int(length) != 1 + 2 * operation_count { return -1 }

		mut active_keys := [max_live_keys]i64{}
		mut active_count := 0
		for operation in 0 .. operation_count {
			offset := 1 + 2 * operation
			opcode := input[offset]
			key := input[offset + 1]
			if key < -2147483648 || key > 2147483647 || opcode < 0 || opcode > 6 { return -1 }
			if opcode >= 3 && key != 0 { return -1 }
			if opcode == 0 {
				mut present := false
				for i in 0 .. active_count { if active_keys[i] == key { present = true } }
				if !present {
					if active_count == max_live_keys { return -1 }
					active_keys[active_count] = key
					active_count++
				}
			} else if opcode == 2 {
				for i in 0 .. active_count {
					if active_keys[i] == key {
						for j in i .. active_count - 1 { active_keys[j] = active_keys[j + 1] }
						active_count--
						break
					}
				}
			} else if opcode == 6 { active_count = 0 }
		}

		mut tree := Tree{}
		tree.root = -1
		for i in 0 .. max_live_keys { tree.nodes[i].left = -1; tree.nodes[i].right = -1 }
		mut results := [max_operations]i64{}
		for operation in 0 .. operation_count {
			offset := 1 + 2 * operation
			opcode := input[offset]
			key := input[offset + 1]
			if opcode == 0 { results[operation] = if insert_key(mut tree, key) { 1 } else { 0 } }
			else if opcode == 1 { results[operation] = if find_key(tree, tree.root, key) { 1 } else { 0 } }
			else if opcode == 2 { results[operation] = if delete_key(mut tree, key) { 1 } else { 0 } }
			else if opcode == 3 { results[operation] = i64(tree.size) }
			else if opcode == 4 { results[operation] = i64(tree.max_size) }
			else if opcode == 5 { results[operation] = if root_weight_balanced(tree) { 1 } else { 0 } }
			else {
				for i in 0 .. max_live_keys { tree.nodes[i].active = false; tree.nodes[i].left = -1; tree.nodes[i].right = -1 }
				tree.root = -1
				tree.size = 0
				tree.max_size = 0
				results[operation] = -2
			}
		}
		output_bytes := (2 + operation_count + tree.size) * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		put_i64_le(mut staged[0], 0, i64(operation_count))
		for operation in 0 .. operation_count { put_i64_le(mut staged[0], (1 + operation) * 8, results[operation]) }
		put_i64_le(mut staged[0], (1 + operation_count) * 8, i64(tree.size))
		tree.order_length = 0
		flatten(mut tree, tree.root)
		for i in 0 .. tree.order_length { put_i64_le(mut staged[0], (2 + operation_count + i) * 8, tree.nodes[tree.order[i]].key) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
