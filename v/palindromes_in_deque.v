module palindromes_in_deque

const max_queries = 32
const max_nodes = max_queries + 2
const alphabet = 26

struct EertreeNode {
	mut:
	length int
	suffix_link int
	next [alphabet]int
}

struct Eertree {
	mut:
	nodes [max_nodes]EertreeNode
}

fn initialize_node(mut tree Eertree, id int, node_length int, suffix_link int) {
	tree.nodes[id].length = node_length
	tree.nodes[id].suffix_link = suffix_link
	for letter in 0 .. alphabet { tree.nodes[id].next[letter] = -1 }
}

fn find_extendable(tree &Eertree, text []int, position int, start int) int {
	mut node := start
	for {
		preceding := position - tree.nodes[node].length - 1
		if preceding >= 0 && text[preceding] == text[position] { return node }
		node = tree.nodes[node].suffix_link
	}
	return 0
}

fn summarize(text []int) (i64, i64, i64) {
	mut tree := Eertree{}
	initialize_node(mut tree, 0, -1, 0)
	initialize_node(mut tree, 1, 0, 0)
	mut node_count := 2
	mut last := 1
	mut longest_prefix := 0
	for position in 0 .. text.len {
		letter := text[position]
		parent := find_extendable(tree, text, position, last)
		mut child := tree.nodes[parent].next[letter]
		if child < 0 {
			child = node_count
			node_count++
			initialize_node(mut tree, child, tree.nodes[parent].length + 2, 0)
			tree.nodes[parent].next[letter] = child
			if tree.nodes[child].length == 1 {
				tree.nodes[child].suffix_link = 1
			} else {
				suffix_parent := find_extendable(tree, text, position, tree.nodes[parent].suffix_link)
				tree.nodes[child].suffix_link = tree.nodes[suffix_parent].next[letter]
			}
		}
		last = child
		if tree.nodes[last].length == position + 1 { longest_prefix = position + 1 }
	}
	return i64(node_count - 2), i64(longest_prefix), i64(tree.nodes[last].length)
}

fn store_i64_le(mut output &u8, offset usize, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'palindromes_in_deque']
pub fn palindromes_in_deque(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 1 + 2 * max_queries { return -1 }
	query_value := unsafe { input[0] }
	if query_value < 1 || query_value > max_queries { return -1 }
	queries := int(query_value)
	if length != usize(1 + 2 * queries) { return -1 }

	mut size := 0
	for query in 0 .. queries {
		operation := unsafe { input[1 + 2 * query] }
		letter := unsafe { input[2 + 2 * query] }
		if operation == 0 || operation == 1 {
			if letter < 0 || letter >= alphabet { return -1 }
			size++
		} else if operation == 2 || operation == 3 {
			if letter != 0 || size == 0 { return -1 }
			size--
		} else { return -1 }
	}
	if unsafe { output == nil } || capacity < usize(24 * queries) { return -2 }

	mut text_storage := [max_queries]int{}
	size = 0
	for query in 0 .. queries {
		operation := int(unsafe { input[1 + 2 * query] })
		letter := int(unsafe { input[2 + 2 * query] })
		if operation == 0 {
			for index := size; index > 0; index-- { text_storage[index] = text_storage[index - 1] }
			text_storage[0] = letter
			size++
		} else if operation == 1 {
			text_storage[size] = letter
			size++
		} else if operation == 2 {
			for index in 1 .. size { text_storage[index - 1] = text_storage[index] }
			size--
		} else { size-- }
		distinct, prefix, suffix := summarize(text_storage[..size])
		offset := usize(24 * query)
		store_i64_le(mut output, offset, distinct)
		store_i64_le(mut output, offset + 8, prefix)
		store_i64_le(mut output, offset + 16, suffix)
	}
	return i64(24 * queries)
}
