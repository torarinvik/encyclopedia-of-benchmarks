module suffix_array_blind_trie

const max_text_length = 32
const max_input_length = 34
const max_nodes = 64

struct TrieNode {
	is_leaf      bool
	split_pos    i32
	leaf_start   i32
	edge_symbol  i32
	first_child  i32
	next_sibling i32
}

struct BlindTrie {
	node  [max_nodes]TrieNode
	count i32
	root  i32
}

fn symbol_at(input []i64, n int, start int, depth int) i32 {
	position := start + depth
	if position >= n { return 0 }
	return i32(input[position + 1]) + 1
}

fn common_prefix(input []i64, n int, left int, right int) int {
	mut depth := 0
	for symbol_at(input, n, left, depth) == symbol_at(input, n, right, depth) {
		depth++
	}
	return depth
}

fn new_node(mut trie &BlindTrie, is_leaf bool, value int) int {
	index := int(trie.count)
	trie.count++
	trie.node[index].is_leaf = is_leaf
	trie.node[index].split_pos = if is_leaf { 0 } else { i32(value) }
	trie.node[index].leaf_start = if is_leaf { i32(value) } else { -1 }
	trie.node[index].first_child = -1
	trie.node[index].next_sibling = -1
	return index
}

fn find_child(trie &BlindTrie, parent int, symbol i32) int {
	mut child := int(trie.node[parent].first_child)
	for child >= 0 {
		if trie.node[child].edge_symbol == symbol { return child }
		if trie.node[child].edge_symbol > symbol { return -1 }
		child = int(trie.node[child].next_sibling)
	}
	return -1
}

fn link_child(mut trie &BlindTrie, parent int, child int) {
	symbol := trie.node[child].edge_symbol
	mut previous := -1
	mut cursor := int(trie.node[parent].first_child)
	for cursor >= 0 && trie.node[cursor].edge_symbol < symbol {
		previous = cursor
		cursor = int(trie.node[cursor].next_sibling)
	}
	trie.node[child].next_sibling = i32(cursor)
	if previous < 0 { trie.node[parent].first_child = i32(child) }
	else { trie.node[previous].next_sibling = i32(child) }
}

fn replace_child(mut trie &BlindTrie, parent int, old_child int, new_child int) {
	mut previous := -1
	mut cursor := int(trie.node[parent].first_child)
	for cursor != old_child {
		previous = cursor
		cursor = int(trie.node[cursor].next_sibling)
	}
	trie.node[new_child].edge_symbol = trie.node[old_child].edge_symbol
	trie.node[new_child].next_sibling = trie.node[old_child].next_sibling
	if previous < 0 { trie.node[parent].first_child = i32(new_child) }
	else { trie.node[previous].next_sibling = i32(new_child) }
}

fn insert_suffix(mut trie &BlindTrie, input []i64, n int, start int) {
	fresh := new_node(mut trie, true, start)
	if trie.node[int(trie.root)].is_leaf {
		old := int(trie.root)
		depth := common_prefix(input, n, int(trie.node[old].leaf_start), start)
		middle := new_node(mut trie, false, depth)
		trie.node[old].edge_symbol = symbol_at(input, n, int(trie.node[old].leaf_start), depth)
		trie.node[fresh].edge_symbol = symbol_at(input, n, start, depth)
		link_child(mut trie, middle, old)
		link_child(mut trie, middle, fresh)
		trie.root = i32(middle)
		return
	}

	mut leaf := int(trie.root)
	for !trie.node[leaf].is_leaf {
		symbol := symbol_at(input, n, start, int(trie.node[leaf].split_pos))
		mut child := find_child(trie, leaf, symbol)
		if child < 0 { child = int(trie.node[leaf].first_child) }
		leaf = child
	}
	old_start := int(trie.node[leaf].leaf_start)
	depth := common_prefix(input, n, start, old_start)
	mut parent := -1
	mut current := int(trie.root)
	for !trie.node[current].is_leaf && int(trie.node[current].split_pos) < depth {
		symbol := symbol_at(input, n, start, int(trie.node[current].split_pos))
		mut child := find_child(trie, current, symbol)
		if child < 0 { child = int(trie.node[current].first_child) }
		parent = current
		current = child
	}
	if !trie.node[current].is_leaf && int(trie.node[current].split_pos) == depth {
		trie.node[fresh].edge_symbol = symbol_at(input, n, start, depth)
		link_child(mut trie, current, fresh)
		return
	}
	middle := new_node(mut trie, false, depth)
	if parent < 0 { trie.root = i32(middle) }
	else { replace_child(mut trie, parent, current, middle) }
	trie.node[current].edge_symbol = symbol_at(input, n, old_start, depth)
	trie.node[fresh].edge_symbol = symbol_at(input, n, start, depth)
	link_child(mut trie, middle, current)
	link_child(mut trie, middle, fresh)
}

fn ordered_leaves(trie &BlindTrie, mut output []i32) int {
	mut stack := [max_nodes]i32{}
	mut top := 1
	mut count := 0
	stack[0] = trie.root
	for top > 0 {
		top--
		node := int(stack[top])
		if trie.node[node].is_leaf {
			output[count] = trie.node[node].leaf_start
			count++
			continue
		}
		mut children := [max_text_length]i32{}
		mut child_count := 0
		mut child := int(trie.node[node].first_child)
		for child >= 0 {
			children[child_count] = i32(child)
			child_count++
			child = int(trie.node[child].next_sibling)
		}
		for child_count > 0 {
			child_count--
			stack[top] = children[child_count]
			top++
		}
	}
	return count
}

fn store_i64_le(mut output []u8, offset int, value int) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

pub fn suffix_array_blind_trie(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_input_length { return -1 }
		count_value := values[0]
		if count_value < 0 || count_value > max_text_length { return -1 }
		count := int(count_value)
		if length != usize(count + 1) { return -1 }
		for index in 0 .. count {
			if values[index + 1] < 0 || values[index + 1] > 255 { return -1 }
		}
		output_bytes := count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		if count == 0 { return 0 }
		input := values[0..length]
		mut output_view := output[0..output_bytes]
		mut trie := BlindTrie{}
		for index in 0 .. max_nodes {
			trie.node[index].first_child = -1
			trie.node[index].next_sibling = -1
		}
		trie.root = i32(new_node(mut trie, true, 0))
		for start in 1 .. count { insert_suffix(mut trie, input, count, start) }
		mut order := [max_text_length]i32{}
		ordered_count := ordered_leaves(trie, mut order[..])
		for index in 0 .. ordered_count { store_i64_le(mut output_view, index * 8, int(order[index])) }
		return i64(output_bytes)
	}
}
