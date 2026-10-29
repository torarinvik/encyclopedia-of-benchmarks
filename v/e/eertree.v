module eertree

const max_text_length = 128
const max_nodes = max_text_length + 2
const alphabet_size = 26

struct EertreeNode {
	mut:
	length int
	suffix_link int
	next [alphabet_size]int
}

struct Eertree {
	mut:
	nodes [max_nodes]EertreeNode
}

fn initialize_node(mut tree Eertree, id int, node_length int, suffix_link int) {
	tree.nodes[id].length = node_length
	tree.nodes[id].suffix_link = suffix_link
	for letter in 0 .. alphabet_size {
		tree.nodes[id].next[letter] = -1
	}
}

fn find_extendable(tree &Eertree, text []i64, position int, start int) int {
	mut node := start
	for {
		preceding := position - 1 - tree.nodes[node].length
		if preceding >= 0 && text[preceding] == text[position] { return node }
		node = tree.nodes[node].suffix_link
	}
	return 0
}

@[export: 'eertree']
pub fn eertree(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_text_length + 1 { return -1 }
	if unsafe { values[0] < 0 || values[0] > max_text_length } { return -1 }
	text_length := int(unsafe { values[0] })
	if length != usize(text_length + 1) { return -1 }
	mut text_storage := [max_text_length]i64{}
	for position in 0 .. text_length {
		value := unsafe { values[position + 1] }
		if value < 0 || value >= alphabet_size { return -1 }
		text_storage[position] = value
	}
	text := text_storage[..text_length]

	mut tree := Eertree{}
	initialize_node(mut tree, 0, -1, 0)
	initialize_node(mut tree, 1, 0, 0)
	mut node_count := 2
	mut longest_suffix := 1
	mut checksum := i64(0)
	for position in 0 .. text_length {
		letter := int(text[position])
		parent := find_extendable(tree, text, position, longest_suffix)
		mut next := tree.nodes[parent].next[letter]
		if next < 0 {
			next = node_count
			node_count++
			initialize_node(mut tree, next, tree.nodes[parent].length + 2, 0)
			tree.nodes[parent].next[letter] = next
			if tree.nodes[next].length == 1 {
				tree.nodes[next].suffix_link = 1
			} else {
				suffix_parent := find_extendable(tree, text, position, tree.nodes[parent].suffix_link)
				suffix := tree.nodes[suffix_parent].next[letter]
				if suffix < 0 { return -1 }
				tree.nodes[next].suffix_link = suffix
			}
		}
		longest_suffix = next
		checksum += i64(position + 1) * i64(node_count - 2)
	}
	return checksum
}
