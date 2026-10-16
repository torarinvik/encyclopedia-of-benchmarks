module red_black_tree_insert_search

const max_operations = 128
const invalid_result = i64(-1)
const capacity_result = i64(-2)

struct Node {
	mut:
	key i64
	left int
	right int
	red bool
}

fn is_red(tree []Node, node int) bool { return node != 0 && tree[node].red }
fn flip_colors(mut tree []Node, node int) {
	tree[node].red = !tree[node].red
	left, right := tree[node].left, tree[node].right
	tree[left].red = !tree[left].red
	tree[right].red = !tree[right].red
}
fn rotate_left(mut tree []Node, node int) int {
	pivot := tree[node].right
	tree[node].right = tree[pivot].left
	tree[pivot].left = node
	tree[pivot].red = tree[node].red
	tree[node].red = true
	return pivot
}
fn rotate_right(mut tree []Node, node int) int {
	pivot := tree[node].left
	tree[node].left = tree[pivot].right
	tree[pivot].right = node
	tree[pivot].red = tree[node].red
	tree[node].red = true
	return pivot
}
fn insert_node(mut tree []Node, node int, key i64, mut next int) int {
	if node == 0 {
		created := next
		next++
		tree[created] = Node{key: key, left: 0, right: 0, red: true}
		return created
	}
	if is_red(tree, tree[node].left) && is_red(tree, tree[node].right) { flip_colors(mut tree, node) }
	if key == tree[node].key { tree[node].key = key }
	else if key < tree[node].key {
		child := insert_node(mut tree, tree[node].left, key, mut next)
		tree[node].left = child
	} else {
		child := insert_node(mut tree, tree[node].right, key, mut next)
		tree[node].right = child
	}
	if is_red(tree, tree[node].right) && !is_red(tree, tree[node].left) { return rotate_left(mut tree, node) }
	if is_red(tree, tree[node].left) && is_red(tree, tree[tree[node].left].left) { return rotate_right(mut tree, node) }
	return node
}
fn find_node(tree []Node, start int, key i64) int {
	mut node := start
	for node != 0 {
		if key < tree[node].key { node = tree[node].left }
		else if key > tree[node].key { node = tree[node].right }
		else { return node }
	}
	return 0
}
fn insertion_sort(mut values []i64, count int) {
	for index in 1 .. count {
		value := values[index]
		mut position := index
		for position > 0 && values[position - 1] > value {
			values[position] = values[position - 1]
			position--
		}
		values[position] = value
	}
}
fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'red_black_tree_insert_search']
pub fn red_black_tree_insert_search(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return invalid_result }
	unsafe {
		count_value := input[0]
		if count_value < 0 || count_value > max_operations || length != usize(1 + 2 * count_value) { return invalid_result }
		operation_count := int(count_value)
		for op in 0 .. operation_count {
			opcode, key := input[1 + 2 * op], input[2 + 2 * op]
			if (opcode != 0 && opcode != 1) || key < -2_147_483_648 || key > 2_147_483_647 { return invalid_result }
		}
		mut tree := []Node{len: max_operations + 1}
		mut keys := []i64{len: max_operations}
		mut search_results := []i64{len: max_operations}
		mut root := 0
		mut next := 1
		mut key_count := 0
		mut search_count := 0
		for op in 0 .. operation_count {
			opcode, key := input[1 + 2 * op], input[2 + 2 * op]
			if opcode == 0 {
				if find_node(tree, root, key) != 0 { return invalid_result }
				root = insert_node(mut tree, root, key, mut next)
				tree[root].red = false
				keys[key_count] = key
				key_count++
			} else {
				search_results[search_count] = if find_node(tree, root, key) != 0 { 1 } else { 0 }
				search_count++
			}
		}
		insertion_sort(mut keys, key_count)
		required := (2 + key_count + search_count) * 8
		if unsafe { output == nil } || capacity < usize(required) { return capacity_result }
		offset := 0
		write_i64_le(mut output, offset, i64(key_count)); offset += 8
		for index in 0 .. key_count { write_i64_le(mut output, offset, keys[index]); offset += 8 }
		write_i64_le(mut output, offset, i64(search_count)); offset += 8
		for index in 0 .. search_count { write_i64_le(mut output, offset, search_results[index]); offset += 8 }
		return i64(required)
	}
}
