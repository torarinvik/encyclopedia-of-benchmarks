module burstsort

const max_strings = 16
const max_string_length = 8
const max_input_words = 145
const max_trie_nodes = 129
const bucket_threshold = 3

struct Burst_Node {
	mut:
	depth int
	burst bool
	children [4]int
	bucket [16]int
	bucket_count int
	terminal [16]int
	terminal_count int
}

struct Burst_State {
	mut:
	nodes [129]Burst_Node
	node_count int
	lengths [16]int
	bytes [128]int
}

fn (mut state Burst_State) new_node(depth int) int {
	if state.node_count >= max_trie_nodes { return -1 }
	node := state.node_count
	state.node_count++
	state.nodes[node].depth = depth
	state.nodes[node].burst = false
	state.nodes[node].bucket_count = 0
	state.nodes[node].terminal_count = 0
	for symbol in 0 .. 4 { state.nodes[node].children[symbol] = -1 }
	return node
}

fn (mut state Burst_State) add_string(node int, string_id int) bool {
	depth := state.nodes[node].depth
	if state.lengths[string_id] == depth {
		terminal_count := state.nodes[node].terminal_count
		if terminal_count >= max_strings { return false }
		state.nodes[node].terminal[terminal_count] = string_id
		state.nodes[node].terminal_count = terminal_count + 1
		return true
	}
	if state.nodes[node].burst {
		symbol := state.bytes[string_id * max_string_length + depth]
		mut child := state.nodes[node].children[symbol]
		if child < 0 {
			child = state.new_node(depth + 1)
			if child < 0 { return false }
			state.nodes[node].children[symbol] = child
		}
		return state.add_string(child, string_id)
	}

	bucket_count := state.nodes[node].bucket_count
	if bucket_count < bucket_threshold {
		state.nodes[node].bucket[bucket_count] = string_id
		state.nodes[node].bucket_count = bucket_count + 1
		return true
	}
	mut pending := [16]int{}
	for index in 0 .. bucket_count { pending[index] = state.nodes[node].bucket[index] }
	state.nodes[node].bucket_count = 0
	state.nodes[node].burst = true
	for index in 0 .. bucket_count {
		symbol := state.bytes[pending[index] * max_string_length + depth]
		mut child := state.nodes[node].children[symbol]
		if child < 0 {
			child = state.new_node(depth + 1)
			if child < 0 { return false }
			state.nodes[node].children[symbol] = child
		}
		if !state.add_string(child, pending[index]) { return false }
	}
	symbol := state.bytes[string_id * max_string_length + depth]
	mut child := state.nodes[node].children[symbol]
	if child < 0 {
		child = state.new_node(depth + 1)
		if child < 0 { return false }
		state.nodes[node].children[symbol] = child
	}
	return state.add_string(child, string_id)
}

fn less_strings(state &Burst_State, left int, right int) bool {
	common_length := state.lengths[left]
	if state.lengths[right] < common_length { common_length = state.lengths[right] }
	for index in 0 .. common_length {
		left_byte := state.bytes[left * max_string_length + index]
		right_byte := state.bytes[right * max_string_length + index]
		if left_byte != right_byte { return left_byte < right_byte }
	}
	return state.lengths[left] < state.lengths[right]
}

fn key_code(state &Burst_State, string_id int) i64 {
	mut code := i64(0)
	mut weight := i64(78125) // 5^(7-j), j is the byte's index from the string's start.
	for index in 0 .. state.lengths[string_id] {
		code += i64(state.bytes[string_id * max_string_length + index] + 1) * weight
		weight /= 5
	}
	return code
}

fn (mut state Burst_State) emit_node(node int, mut rank i64, mut checksum i64) {
	for index in 0 .. state.nodes[node].terminal_count {
		rank++
		checksum += rank * key_code(state, state.nodes[node].terminal[index])
	}
	if state.nodes[node].burst {
		for symbol in 0 .. 4 {
			child := state.nodes[node].children[symbol]
			if child >= 0 { state.emit_node(child, mut rank, mut checksum) }
		}
		return
	}
	bucket_count := state.nodes[node].bucket_count
	if bucket_count > 1 {
		for position in 1 .. bucket_count {
			item := state.nodes[node].bucket[position]
			mut insertion := position
			for insertion > 0 && less_strings(state, item, state.nodes[node].bucket[insertion - 1]) {
				state.nodes[node].bucket[insertion] = state.nodes[node].bucket[insertion - 1]
				insertion--
			}
			state.nodes[node].bucket[insertion] = item
		}
	}
	for index in 0 .. bucket_count {
		rank++
		checksum += rank * key_code(state, state.nodes[node].bucket[index])
	}
}

@[export: 'burstsort']
pub fn burstsort(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_words { return -1 }
		string_count_value := input[0]
		if string_count_value < 0 || string_count_value > max_strings { return -1 }
		string_count := int(string_count_value)
		mut state := Burst_State{}
		mut position := 1
		for string_id in 0 .. string_count {
			if position >= int(length) { return -1 }
			string_length_value := input[position]
			position++
			if string_length_value < 0 || string_length_value > max_string_length { return -1 }
			string_length := int(string_length_value)
			if string_length > int(length) - position { return -1 }
			state.lengths[string_id] = string_length
			for byte_index in 0 .. string_length {
				byte_value := input[position + byte_index]
				if byte_value < 0 || byte_value > 3 { return -1 }
				state.bytes[string_id * max_string_length + byte_index] = int(byte_value)
			}
			position += string_length
		}
		if position != int(length) { return -1 }
		root := state.new_node(0)
		if root < 0 { return -1 }
		for string_id in 0 .. string_count {
			if !state.add_string(root, string_id) { return -1 }
		}
		mut rank := i64(0)
		mut checksum := i64(0)
		state.emit_node(root, mut rank, mut checksum)
		return checksum
	}
}
