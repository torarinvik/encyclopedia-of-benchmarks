package mccat_trie

import "core:c"

MAX_WORDS :: 64
MAX_WORD_LENGTH :: 32
MAX_INPUT_VALUES :: 1 + MAX_WORDS * (1 + MAX_WORD_LENGTH)
MAX_NODES :: MAX_WORDS * MAX_WORD_LENGTH
MAX_OUTPUT_BYTES :: MAX_WORDS * (MAX_WORD_LENGTH + 1)

Node :: struct { value: u8, terminal: bool, postfix, other_char: int }

new_node :: proc "contextless" (nodes: [^]Node, used: ^int, value: u8) -> int {
	used^ += 1
	nodes[used^].value = value
	return used^
}

new_suffix :: proc "contextless" (nodes: [^]Node, used: ^int, input: [^]i64,
	start, word_length: int) -> int {
	root := new_node(nodes, used, u8(input[start]))
	current := root
	for offset := 1; offset < word_length; offset += 1 {
		child := new_node(nodes, used, u8(input[start+offset]))
		nodes[current].postfix = child
		current = child
	}
	nodes[current].terminal = true
	return root
}

insert_word :: proc "contextless" (nodes: [^]Node, used: ^int, current: int, input: [^]i64,
	start, word_length, offset: int) {
	if nodes[current].value == u8(input[start+offset]) {
		if offset+1 == word_length {
			nodes[current].terminal = true
		} else if nodes[current].postfix == 0 {
			nodes[current].postfix = new_suffix(nodes, used, input, start+offset+1, word_length-offset-1)
		} else {
			next := nodes[current].postfix
			insert_word(nodes, used, next, input, start, word_length, offset+1)
		}
	} else if nodes[current].other_char == 0 {
		nodes[current].other_char = new_suffix(nodes, used, input, start+offset, word_length-offset)
	} else {
		next := nodes[current].other_char
		insert_word(nodes, used, next, input, start, word_length, offset)
	}
}

measure_output :: proc "contextless" (nodes: [^]Node, current, depth: int, output_length: ^int) {
	if current == 0 do return
	if nodes[current].terminal do output_length^ += depth+2
	measure_output(nodes, nodes[current].postfix, depth+1, output_length)
	measure_output(nodes, nodes[current].other_char, depth, output_length)
}

emit_output :: proc "contextless" (nodes: [^]Node, current, depth: int, prefix: [^]u8,
	output: [^]u8, position: ^int) {
	if current == 0 do return
	prefix[depth] = nodes[current].value
	if nodes[current].terminal {
		for i := 0; i <= depth; i += 1 {
			output[position^] = prefix[i]
			position^ += 1
		}
		output[position^] = '\n'
		position^ += 1
	}
	emit_output(nodes, nodes[current].postfix, depth+1, prefix, output, position)
	emit_output(nodes, nodes[current].other_char, depth, prefix, output, position)
}

@(export)
mccat_trie :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	if input[0] < 0 || input[0] > MAX_WORDS do return -1
	word_count := int(input[0])
	starts: [MAX_WORDS]int
	lengths: [MAX_WORDS]int
	position := 1
	for index in 0..<word_count {
		if position >= int(length) do return -1
		word_length_value := input[position]
		position += 1
		if word_length_value < 1 || word_length_value > MAX_WORD_LENGTH do return -1
		word_length := int(word_length_value)
		if word_length > int(length)-position do return -1
		starts[index] = position
		lengths[index] = word_length
		for j in 0..<word_length {
			if input[position+j] < 33 || input[position+j] > 126 do return -1
		}
		position += word_length
	}
	if position != int(length) do return -1

	var nodes: [MAX_NODES+1]Node
	used := 0
	root := 0
	for index in 0..<word_count {
		if root == 0 { root = new_suffix(&nodes[0], &used, input, starts[index], lengths[index]) }
		else { insert_word(&nodes[0], &used, root, input, starts[index], lengths[index], 0) }
	}
	output_length := 0
	measure_output(&nodes[0], root, 0, &output_length)
	if output_length > MAX_OUTPUT_BYTES do return -1
	if output_length > 0 && (output == nil || capacity < c.size_t(output_length)) do return -2
	if output_length == 0 do return 0
	prefix: [MAX_WORD_LENGTH]u8
	position = 0
	emit_output(&nodes[0], root, 0, &prefix[0], output, &position)
	return i64(position)
}
