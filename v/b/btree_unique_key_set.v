module btree_unique_key_set

const min_degree = 255
const max_node_keys = 2 * min_degree - 1
const max_node_count = 32
const max_inserts = 2048
const max_queries = 1024
const max_deletes = 1024
const max_output_values = 2 + max_queries + max_inserts

struct BTree {
mut:
	keys [max_node_count][max_node_keys]i32
	children [max_node_count][max_node_keys + 1]int
	key_count [max_node_count]int
	leaf [max_node_count]bool
	used_nodes int
	root int
}

fn new_tree() BTree {
	mut tree := BTree{}
	tree.used_nodes = 1
	tree.leaf[0] = true
	return tree
}

fn (tree &BTree) search(key i32) bool {
	mut node := tree.root
	for {
		mut index := 0
		for index < tree.key_count[node] && key > tree.keys[node][index] { index++ }
		if index < tree.key_count[node] && key == tree.keys[node][index] { return true }
		if tree.leaf[node] { return false }
		node = tree.children[node][index]
	}
}

fn (mut tree BTree) split_child(parent int, child_index int) bool {
	if tree.used_nodes >= max_node_count { return false }
	child := tree.children[parent][child_index]
	sibling := tree.used_nodes
	tree.used_nodes++
	tree.leaf[sibling] = tree.leaf[child]
	for i in 0 .. min_degree - 1 { tree.keys[sibling][i] = tree.keys[child][i + min_degree] }
	if !tree.leaf[child] {
		for i in 0 .. min_degree { tree.children[sibling][i] = tree.children[child][i + min_degree] }
	}
	tree.key_count[sibling] = min_degree - 1
	parent_count := tree.key_count[parent]
	mut i := parent_count + 1
	for i > child_index + 1 { tree.children[parent][i] = tree.children[parent][i - 1]; i-- }
	tree.children[parent][child_index + 1] = sibling
	i = parent_count
	for i > child_index { tree.keys[parent][i] = tree.keys[parent][i - 1]; i-- }
	tree.keys[parent][child_index] = tree.keys[child][min_degree - 1]
	tree.key_count[child] = min_degree - 1
	tree.key_count[parent] = parent_count + 1
	return true
}

fn (mut tree BTree) insert_non_full(node int, key i32) bool {
	mut index := tree.key_count[node]
	if tree.leaf[node] {
		for index > 0 && key < tree.keys[node][index - 1] {
			tree.keys[node][index] = tree.keys[node][index - 1]
			index--
		}
		tree.keys[node][index] = key
		tree.key_count[node]++
		return true
	}
	for index > 0 && key < tree.keys[node][index - 1] { index-- }
	if tree.key_count[tree.children[node][index]] == max_node_keys {
		if !tree.split_child(node, index) { return false }
		if key > tree.keys[node][index] { index++ }
	}
	return tree.insert_non_full(tree.children[node][index], key)
}

fn (mut tree BTree) insert(key i32) bool {
	if tree.key_count[tree.root] == max_node_keys {
		if tree.used_nodes >= max_node_count { return false }
		old_root := tree.root
		root := tree.used_nodes
		tree.used_nodes++
		tree.leaf[root] = false
		tree.children[root][0] = old_root
		tree.root = root
		if !tree.split_child(root, 0) { return false }
	}
	return tree.insert_non_full(tree.root, key)
}

fn (tree &BTree) predecessor(start int) i32 {
	mut node := start
	for !tree.leaf[node] { node = tree.children[node][tree.key_count[node]] }
	return tree.keys[node][tree.key_count[node] - 1]
}

fn (tree &BTree) successor(start int) i32 {
	mut node := start
	for !tree.leaf[node] { node = tree.children[node][0] }
	return tree.keys[node][0]
}

fn (mut tree BTree) merge_children(parent int, index int) {
	left := tree.children[parent][index]
	right := tree.children[parent][index + 1]
	mut left_count := tree.key_count[left]
	tree.keys[left][left_count] = tree.keys[parent][index]
	left_count++
	for i in 0 .. tree.key_count[right] { tree.keys[left][left_count + i] = tree.keys[right][i] }
	if !tree.leaf[left] {
		for i in 0 .. tree.key_count[right] + 1 { tree.children[left][left_count + i] = tree.children[right][i] }
	}
	tree.key_count[left] = left_count + tree.key_count[right]
	parent_count := tree.key_count[parent]
	for i in index + 1 .. parent_count { tree.keys[parent][i - 1] = tree.keys[parent][i] }
	for i in index + 2 .. parent_count + 1 { tree.children[parent][i - 1] = tree.children[parent][i] }
	tree.key_count[parent]--
}

fn (mut tree BTree) borrow_previous(parent int, index int) {
	child := tree.children[parent][index]
	sibling := tree.children[parent][index - 1]
	count := tree.key_count[child]
	mut i := count
	for i > 0 { tree.keys[child][i] = tree.keys[child][i - 1]; i-- }
	if !tree.leaf[child] {
		i = count + 1
		for i > 0 { tree.children[child][i] = tree.children[child][i - 1]; i-- }
	}
	tree.keys[child][0] = tree.keys[parent][index - 1]
	if !tree.leaf[child] { tree.children[child][0] = tree.children[sibling][tree.key_count[sibling]] }
	tree.keys[parent][index - 1] = tree.keys[sibling][tree.key_count[sibling] - 1]
	tree.key_count[child]++
	tree.key_count[sibling]--
}

fn (mut tree BTree) borrow_next(parent int, index int) {
	child := tree.children[parent][index]
	sibling := tree.children[parent][index + 1]
	child_count := tree.key_count[child]
	sibling_count := tree.key_count[sibling]
	tree.keys[child][child_count] = tree.keys[parent][index]
	if !tree.leaf[child] { tree.children[child][child_count + 1] = tree.children[sibling][0] }
	tree.keys[parent][index] = tree.keys[sibling][0]
	for i in 1 .. sibling_count { tree.keys[sibling][i - 1] = tree.keys[sibling][i] }
	if !tree.leaf[sibling] {
		for i in 1 .. sibling_count + 1 { tree.children[sibling][i - 1] = tree.children[sibling][i] }
	}
	tree.key_count[child]++
	tree.key_count[sibling]--
}

fn (mut tree BTree) fill_child(parent int, index int) {
	if index > 0 && tree.key_count[tree.children[parent][index - 1]] >= min_degree {
		tree.borrow_previous(parent, index)
	} else if index < tree.key_count[parent] && tree.key_count[tree.children[parent][index + 1]] >= min_degree {
		tree.borrow_next(parent, index)
	} else {
		tree.merge_children(parent, if index < tree.key_count[parent] { index } else { index - 1 })
	}
}

fn (mut tree BTree) delete_from(node int, key i32) bool {
	mut index := 0
	for index < tree.key_count[node] && tree.keys[node][index] < key { index++ }
	if index < tree.key_count[node] && tree.keys[node][index] == key {
		if tree.leaf[node] {
			for i in index + 1 .. tree.key_count[node] { tree.keys[node][i - 1] = tree.keys[node][i] }
			tree.key_count[node]--
		} else {
			left := tree.children[node][index]
			right := tree.children[node][index + 1]
			if tree.key_count[left] >= min_degree {
				replacement := tree.predecessor(left)
				tree.keys[node][index] = replacement
				return tree.delete_from(left, replacement)
			}
			if tree.key_count[right] >= min_degree {
				replacement := tree.successor(right)
				tree.keys[node][index] = replacement
				return tree.delete_from(right, replacement)
			}
			tree.merge_children(node, index)
			return tree.delete_from(left, key)
		}
		return true
	}
	if tree.leaf[node] { return false }
	was_last := index == tree.key_count[node]
	if tree.key_count[tree.children[node][index]] < min_degree { tree.fill_child(node, index) }
	if was_last && index > tree.key_count[node] { index-- }
	return tree.delete_from(tree.children[node][index], key)
}

fn (mut tree BTree) delete(key i32) bool {
	if !tree.delete_from(tree.root, key) { return false }
	if tree.key_count[tree.root] == 0 && !tree.leaf[tree.root] { tree.root = tree.children[tree.root][0] }
	return true
}

fn (tree &BTree) traverse(node int, mut result [max_output_values]i64, mut length int) {
	for i in 0 .. tree.key_count[node] {
		if !tree.leaf[node] { tree.traverse(tree.children[node][i], mut result, mut length) }
		result[length] = i64(tree.keys[node][i])
		length++
	}
	if !tree.leaf[node] { tree.traverse(tree.children[node][tree.key_count[node]], mut result, mut length) }
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'btree_unique_key_set']
pub fn btree_unique_key_set(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 3 || length > 4096 || unsafe { values == nil } { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > i64(max_inserts) { return -1 }
		insert_count := int(values[0])
		query_offset := 1 + insert_count
		if query_offset >= int(length) || values[query_offset] < 0 || values[query_offset] > i64(max_queries) { return -1 }
		query_count := int(values[query_offset])
		delete_count_offset := query_offset + 1 + query_count
		if delete_count_offset >= int(length) || values[delete_count_offset] < 0 || values[delete_count_offset] > i64(max_deletes) { return -1 }
		delete_count := int(values[delete_count_offset])
		if int(length) != 3 + insert_count + query_count + delete_count { return -1 }

		mut tree := new_tree()
		for i in 0 .. insert_count {
			raw := values[1 + i]
			if raw < -2147483648 || raw > 2147483647 { return -1 }
			key := i32(raw)
			if tree.search(key) || !tree.insert(key) { return -1 }
		}
		mut result := [max_output_values]i64{}
		mut result_length := 0
		result[result_length] = i64(query_count)
		result_length++
		query_start := query_offset + 1
		for i in 0 .. query_count {
			raw := values[query_start + i]
			if raw < -2147483648 || raw > 2147483647 { return -1 }
			result[result_length] = if tree.search(i32(raw)) { i64(1) } else { i64(0) }
			result_length++
		}
		delete_start := delete_count_offset + 1
		for i in 0 .. delete_count {
			raw := values[delete_start + i]
			if raw < -2147483648 || raw > 2147483647 || !tree.delete(i32(raw)) { return -1 }
		}
		count_slot := result_length
		result_length++
		tree.traverse(tree.root, mut result, mut result_length)
		result[count_slot] = i64(result_length - count_slot - 1)
		output_bytes := result_length * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for i in 0 .. result_length { store_i64_le(mut output, i * 8, result[i]) }
		return i64(output_bytes)
	}
}
