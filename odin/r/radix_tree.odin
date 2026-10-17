package radix_tree

import "core:c"

MAX_OPERATIONS :: 256
MAX_WORD_LENGTH :: 32
MAX_ROOT_PREFIX_LENGTH :: MAX_OPERATIONS*MAX_WORD_LENGTH
MAX_NODES :: 1 + 2*MAX_OPERATIONS
MAX_VALID_INPUT_LENGTH :: c.size_t(8705)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(8706)

Radix_Node :: struct {
	prefix: [MAX_WORD_LENGTH]u8,
	prefix_len: int,
	children: [26]u16,
	is_leaf: bool,
}

allocate_node :: proc "contextless" (nodes: [^]Radix_Node, node_count: ^int, prefix: []u8, is_leaf: bool) -> int {
	if node_count^ >= MAX_NODES do return -1
	index := node_count^
	node_count^ += 1
	for position in 0 ..< len(prefix) { nodes[index].prefix[position] = prefix[position] }
	nodes[index].prefix_len = len(prefix)
	nodes[index].is_leaf = is_leaf
	return index
}

insert_word :: proc "contextless" (nodes: [^]Radix_Node, node_count: ^int, root_prefix: [^]u8, root_prefix_len: ^int, node_index: int, word: []u8) -> bool {
	if len(word) == 0 { nodes[node_index].is_leaf = true; return true }
	prefix_len := nodes[node_index].prefix_len
	equal := false
	if node_index == 0 {
		equal = root_prefix_len^ == len(word)
		if equal { for index in 0 ..< len(word) { if root_prefix[index] != word[index] { equal = false; break } } }
	} else {
		equal = prefix_len == len(word)
		if equal { for index in 0 ..< prefix_len { if nodes[node_index].prefix[index] != word[index] { equal = false; break } } }
	}
	if equal && !nodes[node_index].is_leaf { nodes[node_index].is_leaf = true; return true }
	letter := int(word[0]-'a')
	encoded_child := nodes[node_index].children[letter]
	if encoded_child == 0 {
		child := allocate_node(nodes, node_count, word, true)
		if child < 0 do return false
		nodes[node_index].children[letter] = u16(child+1)
		return true
	}
	child := int(encoded_child)-1
	child_prefix_len := nodes[child].prefix_len
	common := 0
	for common < child_prefix_len && common < len(word) && nodes[child].prefix[common] == word[common] { common += 1 }
	if common == child_prefix_len { return insert_word(nodes, node_count, root_prefix, root_prefix_len, child, word[common:]) }
	var old_suffix: [MAX_WORD_LENGTH]u8
	old_suffix_len := child_prefix_len-common
	for index in 0 ..< old_suffix_len { old_suffix[index] = nodes[child].prefix[common+index] }
	intermediate := allocate_node(nodes, node_count, word[:common], false)
	if intermediate < 0 do return false
	for index in 0 ..< old_suffix_len { nodes[child].prefix[index] = old_suffix[index] }
	nodes[child].prefix_len = old_suffix_len
	old_letter := int(old_suffix[0]-'a')
	nodes[intermediate].children[old_letter] = u16(child+1)
	nodes[node_index].children[letter] = u16(intermediate+1)
	if common == len(word) { nodes[intermediate].is_leaf = true; return true }
	return insert_word(nodes, node_count, root_prefix, root_prefix_len, intermediate, word[common:])
}

find_word :: proc "contextless" (nodes: [^]Radix_Node, node_index: int, word: []u8) -> bool {
	if len(word) == 0 do return false
	encoded_child := nodes[node_index].children[int(word[0]-'a')]
	if encoded_child == 0 do return false
	child := int(encoded_child)-1
	prefix_len := nodes[child].prefix_len
	common := 0
	for common < prefix_len && common < len(word) && nodes[child].prefix[common] == word[common] { common += 1 }
	if common != prefix_len do return false
	if common == len(word) { return nodes[child].is_leaf }
	return find_word(nodes, child, word[common:])
}

delete_word :: proc "contextless" (nodes: [^]Radix_Node, root_prefix: [^]u8, root_prefix_len: ^int, node_index: int, word: []u8) -> bool {
	if len(word) == 0 do return false
	letter := int(word[0]-'a')
	encoded_child := nodes[node_index].children[letter]
	if encoded_child == 0 do return false
	child := int(encoded_child)-1
	prefix_len := nodes[child].prefix_len
	common := 0
	for common < prefix_len && common < len(word) && nodes[child].prefix[common] == word[common] { common += 1 }
	if common != prefix_len do return false
	if common != len(word) { return delete_word(nodes, root_prefix, root_prefix_len, child, word[common:]) }
	if !nodes[child].is_leaf do return false
	child_count := 0
	for entry in nodes[child].children { if entry != 0 { child_count += 1 } }
	if child_count == 0 {
		nodes[node_index].children[letter] = 0
		remaining, survivor := 0, 0
		for entry in nodes[node_index].children { if entry != 0 { remaining += 1; survivor = int(entry)-1 } }
		if remaining == 1 && !nodes[node_index].is_leaf {
			survivor_len := nodes[survivor].prefix_len
			if node_index == 0 {
				if root_prefix_len^ + survivor_len > MAX_ROOT_PREFIX_LENGTH do return false
				for index in 0 ..< survivor_len { root_prefix[root_prefix_len^ + index] = nodes[survivor].prefix[index] }
				root_prefix_len^ += survivor_len
			} else {
				parent_len := nodes[node_index].prefix_len
				for index in 0 ..< survivor_len { nodes[node_index].prefix[parent_len+index] = nodes[survivor].prefix[index] }
				nodes[node_index].prefix_len += survivor_len
			}
			nodes[node_index].is_leaf = nodes[survivor].is_leaf
			nodes[node_index].children = nodes[survivor].children
		}
	} else if child_count > 1 {
		nodes[child].is_leaf = false
	} else {
		survivor := 0
		for entry in nodes[child].children { if entry != 0 { survivor = int(entry)-1; break } }
		survivor_len := nodes[survivor].prefix_len
		child_len := nodes[child].prefix_len
		for index in 0 ..< survivor_len { nodes[child].prefix[child_len+index] = nodes[survivor].prefix[index] }
		nodes[child].prefix_len += survivor_len
		nodes[child].is_leaf = nodes[survivor].is_leaf
		nodes[child].children = nodes[survivor].children
	}
	return true
}

radix_tree_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH || length > MAX_VALID_INPUT_LENGTH do return -1
	operation_value := input[0]
	if operation_value < 0 || operation_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_value)
	var nodes: [MAX_NODES]Radix_Node
	node_count := 1
	var root_prefix: [MAX_ROOT_PREFIX_LENGTH]u8
	root_prefix_len := 0
	checksum := i64(0)
	cursor := 1
	for operation in 0 ..< operation_count {
		if cursor+2 > int(length) do return -1
		opcode, word_length_value := input[cursor], input[cursor+1]
		cursor += 2
		if opcode < 0 || opcode > 2 || word_length_value < 1 || word_length_value > MAX_WORD_LENGTH do return -1
		word_length := int(word_length_value)
		if cursor+word_length > int(length) do return -1
		var word: [MAX_WORD_LENGTH]u8
		for index in 0 ..< word_length {
			byte := input[cursor+index]
			if byte < 97 || byte > 122 do return -1
			word[index] = u8(byte)
		}
		cursor += word_length
		if opcode == 0 {
			if !insert_word(&nodes[0], &node_count, &root_prefix[0], &root_prefix_len, 0, word[:word_length]) do return -1
		} else {
			observed := false
			if opcode == 1 { observed = find_word(&nodes[0], 0, word[:word_length])
			} else { observed = delete_word(&nodes[0], &root_prefix[0], &root_prefix_len, 0, word[:word_length]) }
			encoded := i64(0)
			if observed { encoded = 1 }
			checksum += i64(operation+1)*(1+encoded)
		}
	}
	if cursor != int(length) do return -1
	return checksum
}
