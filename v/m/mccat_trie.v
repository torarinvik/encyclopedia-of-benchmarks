module mccat_trie

const max_words = 64
const max_word_length = 32
const max_input_values = 1 + max_words * (1 + max_word_length)
const max_nodes = max_words * max_word_length
const max_output_bytes = max_words * (max_word_length + 1)

struct TrieNode {
	value u8
	terminal bool
	postfix int
	other_char int
}

fn new_node(mut nodes []TrieNode, mut used int, value u8) int {
	used++
	nodes[used].value = value
	return used
}

fn new_suffix(mut nodes []TrieNode, mut used int, input &i64, start int, word_length int) int {
	root := new_node(mut nodes, mut used, u8(unsafe { input[start] }))
	mut current := root
	for offset in 1 .. word_length {
		child := new_node(mut nodes, mut used, u8(unsafe { input[start + offset] }))
		nodes[current].postfix = child
		current = child
	}
	nodes[current].terminal = true
	return root
}

fn insert_word(mut nodes []TrieNode, mut used int, current int, input &i64,
		start int, word_length int, offset int) {
	if nodes[current].value == u8(unsafe { input[start + offset] }) {
		if offset + 1 == word_length {
			nodes[current].terminal = true
		} else if nodes[current].postfix == 0 {
			nodes[current].postfix = new_suffix(mut nodes, mut used, input, start + offset + 1, word_length - offset - 1)
		} else {
			next := nodes[current].postfix
			insert_word(mut nodes, mut used, next, input, start, word_length, offset + 1)
		}
	} else if nodes[current].other_char == 0 {
		nodes[current].other_char = new_suffix(mut nodes, mut used, input, start + offset, word_length - offset)
	} else {
		next := nodes[current].other_char
		insert_word(mut nodes, mut used, next, input, start, word_length, offset)
	}
}

fn measure_output(nodes []TrieNode, current int, depth int, mut output_length int) {
	if current == 0 { return }
	if nodes[current].terminal { output_length += depth + 2 }
	measure_output(nodes, nodes[current].postfix, depth + 1, mut output_length)
	measure_output(nodes, nodes[current].other_char, depth, mut output_length)
}

fn emit_output(nodes []TrieNode, current int, depth int, mut prefix []u8,
		mut output &u8, mut position int) {
	if current == 0 { return }
	prefix[depth] = nodes[current].value
	if nodes[current].terminal {
		for i in 0 .. depth + 1 {
			unsafe { output[position] = prefix[i] }
			position++
		}
		unsafe { output[position] = 10 }
		position++
	}
	emit_output(nodes, nodes[current].postfix, depth + 1, mut prefix, mut output, mut position)
	emit_output(nodes, nodes[current].other_char, depth, mut prefix, mut output, mut position)
}

@[export: 'mccat_trie']
pub fn mccat_trie(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values { return -1 }
	word_count_value := unsafe { input[0] }
	if word_count_value < 0 || word_count_value > max_words { return -1 }
	word_count := int(word_count_value)
	mut starts := []int{len: max_words, init: 0}
	mut lengths := []int{len: max_words, init: 0}
	mut position := 1
	for index in 0 .. word_count {
		if position >= int(length) { return -1 }
		word_length_value := unsafe { input[position] }
		position++
		if word_length_value < 1 || word_length_value > max_word_length { return -1 }
		word_length := int(word_length_value)
		if word_length > int(length) - position { return -1 }
		starts[index] = position
		lengths[index] = word_length
		for j in 0 .. word_length {
			value := unsafe { input[position + j] }
			if value < 33 || value > 126 { return -1 }
		}
		position += word_length
	}
	if position != int(length) { return -1 }

	mut nodes := []TrieNode{len: max_nodes + 1, init: TrieNode{}}
	mut used := 0
	mut root := 0
	for index in 0 .. word_count {
		if root == 0 { root = new_suffix(mut nodes, mut used, input, starts[index], lengths[index]) }
		else { insert_word(mut nodes, mut used, root, input, starts[index], lengths[index], 0) }
	}
	mut output_length := 0
	measure_output(nodes, root, 0, mut output_length)
	if output_length > max_output_bytes { return -1 }
	if output_length > 0 && (unsafe { output == nil } || output_capacity < usize(output_length)) { return -2 }
	if output_length == 0 { return 0 }
	mut prefix := []u8{len: max_word_length, init: 0}
	position = 0
	emit_output(nodes, root, 0, mut prefix, mut output, mut position)
	return i64(position)
}
