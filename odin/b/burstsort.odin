package burstsort

import "core:c"

MAX_STRINGS :: 16
MAX_STRING_LENGTH :: 8
MAX_INPUT_WORDS :: 145
MAX_TRIE_NODES :: 129
BUCKET_THRESHOLD :: 3

Burst_Node :: struct {
	depth: int,
	burst: bool,
	children: [4]int,
	bucket: [MAX_STRINGS]int,
	bucket_count: int,
	terminal: [MAX_STRINGS]int,
	terminal_count: int,
}

Burst_State :: struct {
	nodes: [MAX_TRIE_NODES]Burst_Node,
	node_count: int,
	lengths: [MAX_STRINGS]int,
	bytes: [MAX_STRINGS * MAX_STRING_LENGTH]int,
}

new_node :: proc(state: ^Burst_State, depth: int) -> int {
	if state.node_count >= MAX_TRIE_NODES do return -1
	node := state.node_count
	state.node_count += 1
	state.nodes[node].depth = depth
	state.nodes[node].burst = false
	state.nodes[node].bucket_count = 0
	state.nodes[node].terminal_count = 0
	for symbol := 0; symbol < 4; symbol += 1 { state.nodes[node].children[symbol] = -1 }
	return node
}

add_string :: proc(state: ^Burst_State, node, string_id: int) -> bool {
	depth := state.nodes[node].depth
	if state.lengths[string_id] == depth {
		terminal_count := state.nodes[node].terminal_count
		if terminal_count >= MAX_STRINGS do return false
		state.nodes[node].terminal[terminal_count] = string_id
		state.nodes[node].terminal_count = terminal_count + 1
		return true
	}
	if state.nodes[node].burst {
		symbol := state.bytes[string_id * MAX_STRING_LENGTH + depth]
		child := state.nodes[node].children[symbol]
		if child < 0 {
			child = new_node(state, depth + 1)
			if child < 0 do return false
			state.nodes[node].children[symbol] = child
		}
		return add_string(state, child, string_id)
	}

	bucket_count := state.nodes[node].bucket_count
	if bucket_count < BUCKET_THRESHOLD {
		state.nodes[node].bucket[bucket_count] = string_id
		state.nodes[node].bucket_count = bucket_count + 1
		return true
	}
	var pending: [MAX_STRINGS]int
	for index := 0; index < bucket_count; index += 1 { pending[index] = state.nodes[node].bucket[index] }
	state.nodes[node].bucket_count = 0
	state.nodes[node].burst = true
	for index := 0; index < bucket_count; index += 1 {
		symbol := state.bytes[pending[index] * MAX_STRING_LENGTH + depth]
		child := state.nodes[node].children[symbol]
		if child < 0 {
			child = new_node(state, depth + 1)
			if child < 0 do return false
			state.nodes[node].children[symbol] = child
		}
		if !add_string(state, child, pending[index]) do return false
	}
	symbol := state.bytes[string_id * MAX_STRING_LENGTH + depth]
	child := state.nodes[node].children[symbol]
	if child < 0 {
		child = new_node(state, depth + 1)
		if child < 0 do return false
		state.nodes[node].children[symbol] = child
	}
	return add_string(state, child, string_id)
}

less_strings :: proc(state: ^Burst_State, left, right: int) -> bool {
	common_length := state.lengths[left]
	if state.lengths[right] < common_length do common_length = state.lengths[right]
	for index := 0; index < common_length; index += 1 {
		left_byte := state.bytes[left * MAX_STRING_LENGTH + index]
		right_byte := state.bytes[right * MAX_STRING_LENGTH + index]
		if left_byte != right_byte do return left_byte < right_byte
	}
	return state.lengths[left] < state.lengths[right]
}

key_code :: proc(state: ^Burst_State, string_id: int) -> i64 {
	code: i64 = 0
	weight: i64 = 78125 // 5^(7-j), with j measured from the string's first byte.
	for index := 0; index < state.lengths[string_id]; index += 1 {
		code += i64(state.bytes[string_id * MAX_STRING_LENGTH + index] + 1) * weight
		weight /= 5
	}
	return code
}

emit_node :: proc(state: ^Burst_State, node: int, rank, checksum: ^i64) {
	for index := 0; index < state.nodes[node].terminal_count; index += 1 {
		rank^ += 1
		checksum^ += rank^ * key_code(state, state.nodes[node].terminal[index])
	}
	if state.nodes[node].burst {
		for symbol := 0; symbol < 4; symbol += 1 {
			child := state.nodes[node].children[symbol]
			if child >= 0 do emit_node(state, child, rank, checksum)
		}
		return
	}
	bucket_count := state.nodes[node].bucket_count
	for position := 1; position < bucket_count; position += 1 {
		item := state.nodes[node].bucket[position]
		insertion := position
		for insertion > 0 && less_strings(state, item, state.nodes[node].bucket[insertion-1]) {
			state.nodes[node].bucket[insertion] = state.nodes[node].bucket[insertion-1]
			insertion -= 1
		}
		state.nodes[node].bucket[insertion] = item
	}
	for index := 0; index < bucket_count; index += 1 {
		rank^ += 1
		checksum^ += rank^ * key_code(state, state.nodes[node].bucket[index])
	}
}

@(export)
burstsort :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_WORDS) do return -1
	string_count_value := input[0]
	if string_count_value < 0 || string_count_value > MAX_STRINGS do return -1
	string_count := int(string_count_value)
	var state: Burst_State
	input_position := 1
	for string_id := 0; string_id < string_count; string_id += 1 {
		if input_position >= int(length) do return -1
		string_length_value := input[input_position]
		input_position += 1
		if string_length_value < 0 || string_length_value > MAX_STRING_LENGTH do return -1
		string_length := int(string_length_value)
		if string_length > int(length) - input_position do return -1
		state.lengths[string_id] = string_length
		for byte_index := 0; byte_index < string_length; byte_index += 1 {
			byte_value := input[input_position + byte_index]
			if byte_value < 0 || byte_value > 3 do return -1
			state.bytes[string_id * MAX_STRING_LENGTH + byte_index] = int(byte_value)
		}
		input_position += string_length
	}
	if input_position != int(length) do return -1
	root := new_node(&state, 0)
	if root < 0 do return -1
	for string_id := 0; string_id < string_count; string_id += 1 {
		if !add_string(&state, root, string_id) do return -1
	}
	rank: i64 = 0
	checksum: i64 = 0
	emit_node(&state, root, &rank, &checksum)
	return checksum
}
