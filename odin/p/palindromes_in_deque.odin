package palindromes_in_deque

import "core:c"

MAX_QUERIES :: 32
MAX_NODES :: MAX_QUERIES + 2
ALPHABET :: 26

Node :: struct { length: int, suffix_link: int, next: [ALPHABET]int }
Tree :: struct { nodes: [MAX_NODES]Node }

initialize_node :: proc "contextless" (tree: ^Tree, id, node_length, suffix_link: int) {
	tree.nodes[id].length = node_length
	tree.nodes[id].suffix_link = suffix_link
	for letter := 0; letter < ALPHABET; letter += 1 {
		tree.nodes[id].next[letter] = -1
	}
}

find_extendable :: proc "contextless" (tree: ^Tree, text: []int, position, start: int) -> int {
	node := start
	for {
		preceding := position - tree.nodes[node].length - 1
		if preceding >= 0 && text[preceding] == text[position] do return node
		node = tree.nodes[node].suffix_link
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

summarize :: proc "contextless" (text: []int) -> (i64, i64, i64) {
	var tree: Tree
	for node := 0; node < MAX_NODES; node += 1 {
		initialize_node(&tree, node, 0, 0)
	}
	tree.nodes[0].length = -1
	node_count := 2
	last := 1
	longest_prefix := 0
	for position := 0; position < len(text); position += 1 {
		letter := text[position]
		parent := find_extendable(&tree, text, position, last)
		child := tree.nodes[parent].next[letter]
		if child < 0 {
			child = node_count
			node_count += 1
			initialize_node(&tree, child, tree.nodes[parent].length + 2, 0)
			tree.nodes[parent].next[letter] = child
			if tree.nodes[child].length == 1 {
				tree.nodes[child].suffix_link = 1
			} else {
				suffix_parent := find_extendable(&tree, text, position, tree.nodes[parent].suffix_link)
				tree.nodes[child].suffix_link = tree.nodes[suffix_parent].next[letter]
			}
		}
		last = child
		if tree.nodes[last].length == position + 1 do longest_prefix = position + 1
	}
	return i64(node_count - 2), i64(longest_prefix), i64(tree.nodes[last].length)
}

@(export)
palindromes_in_deque :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(1 + 2 * MAX_QUERIES) do return -1
	query_value := input[0]
	if query_value < 1 || query_value > i64(MAX_QUERIES) do return -1
	queries := int(query_value)
	if length != c.size_t(1 + 2 * queries) do return -1

	size := 0
	for query := 0; query < queries; query += 1 {
		operation := input[1 + 2 * query]
		letter := input[2 + 2 * query]
		if operation == 0 || operation == 1 {
			if letter < 0 || letter >= i64(ALPHABET) do return -1
			size += 1
		} else if operation == 2 || operation == 3 {
			if letter != 0 || size == 0 do return -1
			size -= 1
		} else {
			return -1
		}
	}
	if output == nil || capacity < c.size_t(24 * queries) do return -2

	var text_storage: [MAX_QUERIES]int
	size = 0
	for query := 0; query < queries; query += 1 {
		operation := int(input[1 + 2 * query])
		letter := int(input[2 + 2 * query])
		if operation == 0 {
			for index := size; index > 0; index -= 1 { text_storage[index] = text_storage[index-1] }
			text_storage[0] = letter
			size += 1
		} else if operation == 1 {
			text_storage[size] = letter
			size += 1
		} else if operation == 2 {
			for index := 1; index < size; index += 1 { text_storage[index-1] = text_storage[index] }
			size -= 1
		} else {
			size -= 1
		}
		distinct, prefix, suffix := summarize(text_storage[:size])
		offset := c.size_t(24 * query)
		store_i64_le(output, offset, distinct)
		store_i64_le(output, offset + 8, prefix)
		store_i64_le(output, offset + 16, suffix)
	}
	return i64(24 * queries)
}
