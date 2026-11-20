package suffix_array_blind_trie

import "core:c"

MAX_TEXT_LENGTH :: 32
MAX_INPUT_LENGTH :: 34
MAX_NODES :: 64

Trie_Node :: struct {
	is_leaf: bool,
	split_pos: i32,
	leaf_start: i32,
	edge_symbol: i32,
	first_child: i32,
	next_sibling: i32,
}

Blind_Trie :: struct {
	node: [MAX_NODES]Trie_Node,
	count: i32,
	root: i32,
}

symbol_at :: proc "contextless" (values: [^]i64, n, start, depth: i32) -> i32 {
	position := start + depth
	if position >= n do return 0
	return i32(values[int(position + 1)]) + 1
}

common_prefix :: proc "contextless" (values: [^]i64, n, left, right: i32) -> i32 {
	depth := i32(0)
	for symbol_at(values, n, left, depth) == symbol_at(values, n, right, depth) {
		depth += 1
	}
	return depth
}

new_node :: proc "contextless" (trie: ^Blind_Trie, is_leaf: bool, value: i32) -> i32 {
	index := trie.count
	trie.count += 1
	trie.node[int(index)].is_leaf = is_leaf
	trie.node[int(index)].split_pos = 0
	trie.node[int(index)].leaf_start = -1
	if is_leaf {
		trie.node[int(index)].leaf_start = value
	} else {
		trie.node[int(index)].split_pos = value
	}
	trie.node[int(index)].first_child = -1
	trie.node[int(index)].next_sibling = -1
	return index
}

find_child :: proc "contextless" (trie: ^Blind_Trie, parent, symbol: i32) -> i32 {
	child := trie.node[int(parent)].first_child
	for child >= 0 {
		if trie.node[int(child)].edge_symbol == symbol do return child
		if trie.node[int(child)].edge_symbol > symbol do return -1
		child = trie.node[int(child)].next_sibling
	}
	return -1
}

link_child :: proc "contextless" (trie: ^Blind_Trie, parent, child: i32) {
	previous := i32(-1)
	cursor := trie.node[int(parent)].first_child
	symbol := trie.node[int(child)].edge_symbol
	for cursor >= 0 && trie.node[int(cursor)].edge_symbol < symbol {
		previous = cursor
		cursor = trie.node[int(cursor)].next_sibling
	}
	trie.node[int(child)].next_sibling = cursor
	if previous < 0 {
		trie.node[int(parent)].first_child = child
	} else {
		trie.node[int(previous)].next_sibling = child
	}
}

replace_child :: proc "contextless" (trie: ^Blind_Trie, parent, old_child, new_child: i32) {
	previous := i32(-1)
	cursor := trie.node[int(parent)].first_child
	for cursor != old_child {
		previous = cursor
		cursor = trie.node[int(cursor)].next_sibling
	}
	trie.node[int(new_child)].edge_symbol = trie.node[int(old_child)].edge_symbol
	trie.node[int(new_child)].next_sibling = trie.node[int(old_child)].next_sibling
	if previous < 0 {
		trie.node[int(parent)].first_child = new_child
	} else {
		trie.node[int(previous)].next_sibling = new_child
	}
}

insert_suffix :: proc "contextless" (trie: ^Blind_Trie, values: [^]i64, n, start: i32) {
	fresh := new_node(trie, true, start)
	if trie.node[int(trie.root)].is_leaf {
		old := trie.root
		depth := common_prefix(values, n, trie.node[int(old)].leaf_start, start)
		middle := new_node(trie, false, depth)
		trie.node[int(old)].edge_symbol = symbol_at(values, n, trie.node[int(old)].leaf_start, depth)
		trie.node[int(fresh)].edge_symbol = symbol_at(values, n, start, depth)
		link_child(trie, middle, old)
		link_child(trie, middle, fresh)
		trie.root = middle
		return
	}

	leaf := trie.root
	for !trie.node[int(leaf)].is_leaf {
		symbol := symbol_at(values, n, start, trie.node[int(leaf)].split_pos)
		child := find_child(trie, leaf, symbol)
		if child < 0 do child = trie.node[int(leaf)].first_child
		leaf = child
	}
	old_start := trie.node[int(leaf)].leaf_start
	depth := common_prefix(values, n, start, old_start)
	parent := i32(-1)
	current := trie.root
	for !trie.node[int(current)].is_leaf && trie.node[int(current)].split_pos < depth {
		symbol := symbol_at(values, n, start, trie.node[int(current)].split_pos)
		child := find_child(trie, current, symbol)
		if child < 0 do child = trie.node[int(current)].first_child
		parent = current
		current = child
	}
	if !trie.node[int(current)].is_leaf && trie.node[int(current)].split_pos == depth {
		trie.node[int(fresh)].edge_symbol = symbol_at(values, n, start, depth)
		link_child(trie, current, fresh)
		return
	}
	middle := new_node(trie, false, depth)
	if parent < 0 {
		trie.root = middle
	} else {
		replace_child(trie, parent, current, middle)
	}
	trie.node[int(current)].edge_symbol = symbol_at(values, n, old_start, depth)
	trie.node[int(fresh)].edge_symbol = symbol_at(values, n, start, depth)
	link_child(trie, middle, current)
	link_child(trie, middle, fresh)
}

ordered_leaves :: proc "contextless" (trie: ^Blind_Trie, output: [^]i32) -> i32 {
	stack: [MAX_NODES]i32
	top := 0
	count := 0
	stack[top] = trie.root
	top += 1
	for top > 0 {
		top -= 1
		node := stack[top]
		if trie.node[int(node)].is_leaf {
			output[count] = trie.node[int(node)].leaf_start
			count += 1
			continue
		}
		children: [MAX_TEXT_LENGTH]i32
		child_count := 0
		child := trie.node[int(node)].first_child
		for child >= 0 {
			children[child_count] = child
			child_count += 1
			child = trie.node[int(child)].next_sibling
		}
		for child_count > 0 {
			child_count -= 1
			stack[top] = children[child_count]
			top += 1
		}
	}
	return count
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
suffix_array_blind_trie :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	count_value := values[0]
	if count_value < 0 || count_value > MAX_TEXT_LENGTH do return -1
	count := i32(count_value)
	if length != c.size_t(count + 1) do return -1
	for index := 0; index < int(count); index += 1 {
		if values[index + 1] < 0 || values[index + 1] > 255 do return -1
	}
	output_bytes := c.size_t(count) * 8
	if output == nil || capacity < output_bytes do return -2
	if count == 0 do return 0

	trie: Blind_Trie
	for index := 0; index < MAX_NODES; index += 1 {
		trie.node[index].first_child = -1
		trie.node[index].next_sibling = -1
	}
	trie.root = new_node(&trie, true, 0)
	for start := i32(1); start < count; start += 1 {
		insert_suffix(&trie, values, count, start)
	}
	order: [MAX_TEXT_LENGTH]i32
	ordered_count := ordered_leaves(&trie, &order[0])
	for index := 0; index < ordered_count; index += 1 {
		store_i64_le(output, index * 8, i64(order[index]))
	}
	return i64(output_bytes)
}
