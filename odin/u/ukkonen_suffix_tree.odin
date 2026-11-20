package ukkonen_suffix_tree

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_INPUT_LENGTH :: 66
MAX_SYMBOLS :: MAX_TEXT_LENGTH + 1
MAX_NODES :: 130
OPEN_END :: -1

Suffix_Node :: struct {
	edge_start: int,
	edge_end: int,
	suffix_link: int,
	suffix_start: int,
	leaf: bool,
	children: [5]int,
}

Ukkonen_State :: struct {
	symbols: [MAX_SYMBOLS]int,
	symbol_count: int,
	leaf_end: int,
	nodes: [MAX_NODES]Suffix_Node,
	node_count: int,
}

new_node :: proc(state: ^Ukkonen_State, edge_start, edge_end: int, is_leaf: bool, suffix_start: int) -> int {
	if state.node_count >= MAX_NODES do return -1
	node := state.node_count
	state.node_count += 1
	state.nodes[node].edge_start = edge_start
	state.nodes[node].edge_end = edge_end
	state.nodes[node].suffix_link = 0
	state.nodes[node].suffix_start = suffix_start
	state.nodes[node].leaf = is_leaf
	for symbol := 0; symbol < 5; symbol += 1 { state.nodes[node].children[symbol] = -1 }
	return node
}

edge_length :: proc(state: ^Ukkonen_State, node: int) -> int {
	end := state.nodes[node].edge_end
	if state.nodes[node].leaf do end = state.leaf_end + 1
	return end - state.nodes[node].edge_start
}

build_online_tree :: proc(state: ^Ukkonen_State) -> bool {
	root := new_node(state, 0, 0, false, -1)
	if root != 0 do return false
	state.nodes[root].suffix_link = root
	active_node, active_edge, active_length, remaining := root, 0, 0, 0
	state.leaf_end = -1
	for position := 0; position < state.symbol_count; position += 1 {
		state.leaf_end = position
		remaining += 1
		last_internal := -1
		for remaining > 0 {
			if active_length == 0 do active_edge = position
			active_symbol := state.symbols[active_edge]
			next := state.nodes[active_node].children[active_symbol]
			if next < 0 {
				suffix_start := position - remaining + 1
				next = new_node(state, position, OPEN_END, true, suffix_start)
				if next < 0 do return false
				state.nodes[active_node].children[active_symbol] = next
				if last_internal >= 0 {
					state.nodes[last_internal].suffix_link = active_node
					last_internal = -1
				}
			} else {
				next_length := edge_length(state, next)
				if active_length >= next_length {
					active_edge += next_length
					active_length -= next_length
					active_node = next
					continue
				}
				next_start := state.nodes[next].edge_start
				if state.symbols[next_start + active_length] == state.symbols[position] {
					if last_internal >= 0 && active_node != root {
						state.nodes[last_internal].suffix_link = active_node
						last_internal = -1
					}
					active_length += 1
					break
				}
				split := new_node(state, next_start, next_start + active_length, false, -1)
				if split < 0 do return false
				state.nodes[active_node].children[active_symbol] = split
				state.nodes[next].edge_start += active_length
				old_symbol := state.symbols[state.nodes[next].edge_start]
				state.nodes[split].children[old_symbol] = next
				suffix_start := position - remaining + 1
				leaf := new_node(state, position, OPEN_END, true, suffix_start)
				if leaf < 0 do return false
				state.nodes[split].children[state.symbols[position]] = leaf
				if last_internal >= 0 do state.nodes[last_internal].suffix_link = split
				last_internal = split
			}

			remaining -= 1
			if active_node == root && active_length > 0 {
				active_length -= 1
				active_edge = position - remaining + 1
			} else if active_node != root {
				active_node = state.nodes[active_node].suffix_link
			}
		}
	}
	return true
}

push_token :: proc(rank, checksum: ^i64, token: i64) {
	rank^ += 1
	checksum^ += rank^ * token
}

emit_node :: proc(state: ^Ukkonen_State, node: int, is_root: bool,
	rank, checksum, distinct_substrings: ^i64) {
	if is_root do push_token(rank, checksum, 0)
	for symbol := 0; symbol < 5; symbol += 1 {
		child := state.nodes[node].children[symbol]
		if child < 0 do continue
		end := state.nodes[child].edge_end
		if state.nodes[child].leaf do end = state.leaf_end + 1
		start := state.nodes[child].edge_start
		push_token(rank, checksum, 1)
		push_token(rank, checksum, i64(end - start))
		for index := start; index < end; index += 1 {
			value := state.symbols[index]
			push_token(rank, checksum, i64(value + 1))
			if value != 4 do distinct_substrings^ += 1
		}
		if state.nodes[child].leaf {
			push_token(rank, checksum, 2)
			push_token(rank, checksum, i64(state.nodes[child].suffix_start + 1))
		} else {
			push_token(rank, checksum, 3)
			emit_node(state, child, false, rank, checksum, distinct_substrings)
			push_token(rank, checksum, 4)
		}
	}
	if is_root do push_token(rank, checksum, 4)
}

@(export)
ukkonen_suffix_tree :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	text_length_value := input[0]
	if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH do return -1
	text_length := int(text_length_value)
	if int(length) != text_length + 1 do return -1
	var state: Ukkonen_State
	for index := 0; index < text_length; index += 1 {
		symbol := input[index + 1]
		if symbol < 0 || symbol > 3 do return -1
		state.symbols[index] = int(symbol)
	}
	state.symbols[text_length] = 4
	state.symbol_count = text_length + 1
	if !build_online_tree(&state) do return -1
	rank: i64 = 0
	checksum: i64 = 0
	distinct_substrings: i64 = 0
	emit_node(&state, 0, true, &rank, &checksum, &distinct_substrings)
	return i64(state.node_count) * (i64(1) << 44) + (distinct_substrings << 32) + checksum
}
