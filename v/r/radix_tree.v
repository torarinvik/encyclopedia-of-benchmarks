module radix_tree

const max_operations = 256
const max_word_length = 32
const max_root_prefix_length = max_operations * max_word_length
const max_nodes = 1 + 2 * max_operations
const max_valid_input_length = 8705
const max_parseable_input_length = 8706

struct RadixNode {
	mut:
	prefix [max_word_length]u8
	prefix_len int
	children [26]u16
	is_leaf bool
}

fn allocate_node(mut nodes []RadixNode, mut node_count int, prefix []u8, is_leaf bool) int {
	if node_count >= max_nodes { return -1 }
	index := node_count
	node_count++
	for position in 0 .. prefix.len { nodes[index].prefix[position] = prefix[position] }
	nodes[index].prefix_len = prefix.len
	nodes[index].is_leaf = is_leaf
	return index
}

fn insert_word(mut nodes []RadixNode, mut node_count int, mut root_prefix []u8, mut root_prefix_len int, node_index int, word []u8) bool {
	if word.len == 0 { nodes[node_index].is_leaf = true; return true }
	prefix_len := nodes[node_index].prefix_len
	mut equal := false
	if node_index == 0 {
		equal = root_prefix_len == word.len
		if equal { for index in 0 .. word.len { if root_prefix[index] != word[index] { equal = false; break } } }
	} else {
		equal = prefix_len == word.len
		if equal { for index in 0 .. prefix_len { if nodes[node_index].prefix[index] != word[index] { equal = false; break } } }
	}
	if equal && !nodes[node_index].is_leaf { nodes[node_index].is_leaf = true; return true }
	letter := int(word[0] - u8(`a`))
	encoded_child := nodes[node_index].children[letter]
	if encoded_child == 0 {
		child := allocate_node(mut nodes, mut node_count, word, true)
		if child < 0 { return false }
		nodes[node_index].children[letter] = u16(child + 1)
		return true
	}
	child := int(encoded_child) - 1
	child_prefix_len := nodes[child].prefix_len
	mut common := 0
	for common < child_prefix_len && common < word.len && nodes[child].prefix[common] == word[common] { common++ }
	if common == child_prefix_len { return insert_word(mut nodes, mut node_count, mut root_prefix, mut root_prefix_len, child, word[common..]) }
	mut old_suffix := []u8{len: child_prefix_len - common}
	for index in 0 .. old_suffix.len { old_suffix[index] = nodes[child].prefix[common + index] }
	intermediate := allocate_node(mut nodes, mut node_count, word[..common], false)
	if intermediate < 0 { return false }
	for index in 0 .. old_suffix.len { nodes[child].prefix[index] = old_suffix[index] }
	nodes[child].prefix_len = old_suffix.len
	old_letter := int(old_suffix[0] - u8(`a`))
	nodes[intermediate].children[old_letter] = u16(child + 1)
	nodes[node_index].children[letter] = u16(intermediate + 1)
	if common == word.len { nodes[intermediate].is_leaf = true; return true }
	return insert_word(mut nodes, mut node_count, mut root_prefix, mut root_prefix_len, intermediate, word[common..])
}

fn find_word(nodes []RadixNode, node_index int, word []u8) bool {
	if word.len == 0 { return false }
	encoded_child := nodes[node_index].children[int(word[0] - u8(`a`))]
	if encoded_child == 0 { return false }
	child := int(encoded_child) - 1
	prefix_len := nodes[child].prefix_len
	mut common := 0
	for common < prefix_len && common < word.len && nodes[child].prefix[common] == word[common] { common++ }
	if common != prefix_len { return false }
	if common == word.len { return nodes[child].is_leaf }
	return find_word(nodes, child, word[common..])
}

fn delete_word(mut nodes []RadixNode, mut root_prefix []u8, mut root_prefix_len int, node_index int, word []u8) bool {
	if word.len == 0 { return false }
	letter := int(word[0] - u8(`a`))
	encoded_child := nodes[node_index].children[letter]
	if encoded_child == 0 { return false }
	child := int(encoded_child) - 1
	prefix_len := nodes[child].prefix_len
	mut common := 0
	for common < prefix_len && common < word.len && nodes[child].prefix[common] == word[common] { common++ }
	if common != prefix_len { return false }
	if common != word.len { return delete_word(mut nodes, mut root_prefix, mut root_prefix_len, child, word[common..]) }
	if !nodes[child].is_leaf { return false }
	mut child_count := 0
	for entry in nodes[child].children { if entry != 0 { child_count++ } }
	if child_count == 0 {
		nodes[node_index].children[letter] = 0
		mut remaining := 0
		mut survivor := 0
		for entry in nodes[node_index].children { if entry != 0 { remaining++; survivor = int(entry) - 1 } }
		if remaining == 1 && !nodes[node_index].is_leaf {
			survivor_len := nodes[survivor].prefix_len
			if node_index == 0 {
				if root_prefix_len + survivor_len > max_root_prefix_length { return false }
				for index in 0 .. survivor_len { root_prefix[root_prefix_len + index] = nodes[survivor].prefix[index] }
				root_prefix_len += survivor_len
			} else {
				parent_len := nodes[node_index].prefix_len
				for index in 0 .. survivor_len { nodes[node_index].prefix[parent_len + index] = nodes[survivor].prefix[index] }
				nodes[node_index].prefix_len += survivor_len
			}
			nodes[node_index].is_leaf = nodes[survivor].is_leaf
			nodes[node_index].children = nodes[survivor].children
		}
	} else if child_count > 1 {
		nodes[child].is_leaf = false
	} else {
		mut survivor := 0
		for entry in nodes[child].children { if entry != 0 { survivor = int(entry) - 1; break } }
		survivor_len := nodes[survivor].prefix_len
		child_len := nodes[child].prefix_len
		for index in 0 .. survivor_len { nodes[child].prefix[child_len + index] = nodes[survivor].prefix[index] }
		nodes[child].prefix_len += survivor_len
		nodes[child].is_leaf = nodes[survivor].is_leaf
		nodes[child].children = nodes[survivor].children
	}
	return true
}

@[export: 'radix_tree_benchmark']
pub fn radix_tree_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } { return -1 }
	if length < 1 || length > usize(max_parseable_input_length) || length > usize(max_valid_input_length) { return -1 }
	unsafe {
		operation_value := input[0]
		if operation_value < 0 || operation_value > max_operations { return -1 }
		operation_count := int(operation_value)
		mut nodes := []RadixNode{len: max_nodes}
		mut node_count := 1
		mut root_prefix := []u8{len: max_root_prefix_length}
		mut root_prefix_len := 0
		mut checksum := i64(0)
		mut cursor := 1
		for operation in 0 .. operation_count {
			if cursor + 2 > int(length) { return -1 }
			opcode, word_length_value := input[cursor], input[cursor + 1]
			cursor += 2
			if opcode < 0 || opcode > 2 || word_length_value < 1 || word_length_value > max_word_length { return -1 }
			word_length := int(word_length_value)
			if cursor + word_length > int(length) { return -1 }
			mut word := []u8{len: word_length}
			for index in 0 .. word_length {
				byte := input[cursor + index]
				if byte < 97 || byte > 122 { return -1 }
				word[index] = u8(byte)
			}
			cursor += word_length
			if opcode == 0 {
				if !insert_word(mut nodes, mut node_count, mut root_prefix, mut root_prefix_len, 0, word) { return -1 }
			} else {
				observed := if opcode == 1 { find_word(nodes, 0, word) } else { delete_word(mut nodes, mut root_prefix, mut root_prefix_len, 0, word) }
				observed_value := if observed { i64(1) } else { i64(0) }
				checksum += i64(operation + 1) * (1 + observed_value)
			}
		}
		if cursor != int(length) { return -1 }
		return checksum
	}
}
