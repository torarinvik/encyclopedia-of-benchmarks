package suffix_trie

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_PATTERN_LENGTH :: 16
MAX_INPUT_LENGTH :: 83
MAX_NODES :: 1 + MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) / 2

@(export)
suffix_trie_search :: proc "c" (input: [^]i64, input_length: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH do return -1
	text_length_value := input[0]
	pattern_length_value := input[1]
	if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH ||
		pattern_length_value < 0 || pattern_length_value > MAX_PATTERN_LENGTH do return -1
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if int(input_length) != 2+text_length+pattern_length do return -1
	text: [MAX_TEXT_LENGTH]u8
	pattern: [MAX_PATTERN_LENGTH]u8
	for i := 0; i < text_length; i += 1 {
		code := input[2+i]
		if code < 0 || code > 127 do return -1
		text[i] = u8(code)
	}
	for i := 0; i < pattern_length; i += 1 {
		code := input[2+text_length+i]
		if code < 0 || code > 127 do return -1
		pattern[i] = u8(code)
	}

	first_child: [MAX_NODES]int32
	next_sibling: [MAX_NODES]int32
	edge_code: [MAX_NODES]u8
	for i := 0; i < MAX_NODES; i += 1 {
		first_child[i] = -1
		next_sibling[i] = -1
	}
	node_count := 1
	for start := 0; start < text_length; start += 1 {
		parent := 0
		for position := start; position < text_length; position += 1 {
			code := text[position]
			child := first_child[parent]
			for child >= 0 && edge_code[child] != code { child = next_sibling[child] }
			if child < 0 {
				child = int32(node_count)
				node_count += 1
				edge_code[child] = code
				next_sibling[child] = first_child[parent]
				first_child[parent] = child
			}
			parent = int(child)
		}
	}
	parent := 0
	for i := 0; i < pattern_length; i += 1 {
		child := first_child[parent]
		for child >= 0 && edge_code[child] != pattern[i] { child = next_sibling[child] }
		if child < 0 do return 0
		parent = int(child)
	}
	return 1
}
