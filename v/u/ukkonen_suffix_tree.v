module ukkonen_suffix_tree

const max_text_length = 64
const max_input_length = 66
const max_symbols = 65
const max_nodes = 130

struct Suffix_Node {
	mut:
	edge_start int
	edge_end int
	suffix_link int
	suffix_start int
	leaf bool
	children [5]int
}

struct Ukkonen_State {
	mut:
	symbols [max_symbols]int
	symbol_count int
	leaf_end int
	nodes [max_nodes]Suffix_Node
	node_count int
}

struct Accumulator {
	mut:
	rank i64
	checksum i64
	distinct_substrings i64
}

fn (mut state Ukkonen_State) new_node(edge_start int, edge_end int, is_leaf bool, suffix_start int) int {
	if state.node_count >= max_nodes { return -1 }
	node := state.node_count
	state.node_count++
	state.nodes[node].edge_start = edge_start
	state.nodes[node].edge_end = edge_end
	state.nodes[node].suffix_link = 0
	state.nodes[node].suffix_start = suffix_start
	state.nodes[node].leaf = is_leaf
	for symbol in 0 .. 5 { state.nodes[node].children[symbol] = -1 }
	return node
}

fn (state &Ukkonen_State) edge_length(node int) int {
	mut edge_end := state.nodes[node].edge_end
	if state.nodes[node].leaf { edge_end = state.leaf_end + 1 }
	return edge_end - state.nodes[node].edge_start
}

fn (mut state Ukkonen_State) build_online_tree() bool {
	root := state.new_node(0, 0, false, -1)
	if root != 0 { return false }
	state.nodes[root].suffix_link = root
	mut active_node := root
	mut active_edge := 0
	mut active_length := 0
	mut remaining := 0
	state.leaf_end = -1
	for position in 0 .. state.symbol_count {
		state.leaf_end = position
		remaining++
		mut last_internal := -1
		for remaining > 0 {
			if active_length == 0 { active_edge = position }
			active_symbol := state.symbols[active_edge]
			mut next := state.nodes[active_node].children[active_symbol]
			if next < 0 {
				suffix_start := position - remaining + 1
				next = state.new_node(position, -1, true, suffix_start)
				if next < 0 { return false }
				state.nodes[active_node].children[active_symbol] = next
				if last_internal >= 0 {
					state.nodes[last_internal].suffix_link = active_node
					last_internal = -1
				}
			} else {
				next_length := state.edge_length(next)
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
					active_length++
					break
				}
				split := state.new_node(next_start, next_start + active_length, false, -1)
				if split < 0 { return false }
				state.nodes[active_node].children[active_symbol] = split
				state.nodes[next].edge_start += active_length
				old_symbol := state.symbols[state.nodes[next].edge_start]
				state.nodes[split].children[old_symbol] = next
				suffix_start := position - remaining + 1
				leaf := state.new_node(position, -1, true, suffix_start)
				if leaf < 0 { return false }
				state.nodes[split].children[state.symbols[position]] = leaf
				if last_internal >= 0 { state.nodes[last_internal].suffix_link = split }
				last_internal = split
			}
			remaining--
			if active_node == root && active_length > 0 {
				active_length--
				active_edge = position - remaining + 1
			} else if active_node != root {
				active_node = state.nodes[active_node].suffix_link
			}
		}
	}
	return true
}

fn (mut accumulator Accumulator) push_token(token i64) {
	accumulator.rank++
	accumulator.checksum += accumulator.rank * token
}

fn (state &Ukkonen_State) emit_node(node int, is_root bool, mut accumulator Accumulator) {
	if is_root { accumulator.push_token(0) }
	for symbol in 0 .. 5 {
		child := state.nodes[node].children[symbol]
		if child < 0 { continue }
		mut edge_end := state.nodes[child].edge_end
		if state.nodes[child].leaf { edge_end = state.leaf_end + 1 }
		edge_start := state.nodes[child].edge_start
		accumulator.push_token(1)
		accumulator.push_token(i64(edge_end - edge_start))
		for index in edge_start .. edge_end {
			value := state.symbols[index]
			accumulator.push_token(i64(value + 1))
			if value != 4 { accumulator.distinct_substrings++ }
		}
		if state.nodes[child].leaf {
			accumulator.push_token(2)
			accumulator.push_token(i64(state.nodes[child].suffix_start + 1))
		} else {
			accumulator.push_token(3)
			state.emit_node(child, false, mut accumulator)
			accumulator.push_token(4)
		}
	}
	if is_root { accumulator.push_token(4) }
}

@[export: 'ukkonen_suffix_tree']
pub fn ukkonen_suffix_tree(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		text_length_value := input[0]
		if text_length_value < 0 || text_length_value > max_text_length { return -1 }
		text_length := int(text_length_value)
		if int(length) != text_length + 1 { return -1 }
		mut state := Ukkonen_State{}
		for index in 0 .. text_length {
			symbol := input[index + 1]
			if symbol < 0 || symbol > 3 { return -1 }
			state.symbols[index] = int(symbol)
		}
		state.symbols[text_length] = 4
		state.symbol_count = text_length + 1
		if !state.build_online_tree() { return -1 }
		mut accumulator := Accumulator{}
		state.emit_node(0, true, mut accumulator)
		result := i64(state.node_count) * (i64(1) << 44) + (accumulator.distinct_substrings << 32) + accumulator.checksum
		return result
	}
}
