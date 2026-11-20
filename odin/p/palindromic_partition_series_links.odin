package palindromic_partition_series_links

import "core:c"

MAX_TEXT :: 64
MAX_NODES :: MAX_TEXT + 2
ALPHABET :: 4
MAX_WORDS :: MAX_TEXT + 1

Node :: struct {
	length: int,
	suffix_link: int,
	difference: int,
	series_link: int,
	series_best: int,
	series_start: int,
	next: [ALPHABET]int,
}

initialize_node :: proc "contextless" (nodes: ^[MAX_NODES]Node, id, length, suffix_link: int) {
	nodes[id].length = length
	nodes[id].suffix_link = suffix_link
	nodes[id].difference = 0
	nodes[id].series_link = 1
	nodes[id].series_best = 0
	nodes[id].series_start = 0
	for symbol := 0; symbol < ALPHABET; symbol += 1 {
		nodes[id].next[symbol] = 0
	}
}

find_extendable :: proc "contextless" (nodes: ^[MAX_NODES]Node, text: []int, position, start: int) -> int {
	node := start
	for {
		preceding := position - 1 - nodes[node].length
		if preceding >= 0 && text[preceding] == text[position] do return node
		node = nodes[node].suffix_link
	}
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := cast(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(8*byte)) & 255)
	}
}

@(export)
palindromic_partition_series_links :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_TEXT + 2) do return -1
	if input[0] < 0 || input[0] > i64(MAX_TEXT) do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	var text_storage: [MAX_TEXT]int
	for position := 0; position < n; position += 1 {
		symbol := input[position + 1]
		if symbol < 0 || symbol >= i64(ALPHABET) do return -1
		text_storage[position] = int(symbol)
	}
	text := text_storage[:n]

	var nodes: [MAX_NODES]Node
	initialize_node(&nodes, 0, 0, 1)
	initialize_node(&nodes, 1, -1, 1)
	node_count := 2
	last := 0
	var dp: [MAX_TEXT + 1]int
	var predecessor: [MAX_TEXT + 1]int
	for i := 0; i <= MAX_TEXT; i += 1 { dp[i] = MAX_TEXT + 1 }
	dp[0] = 0

	for position := 0; position < n; position += 1 {
		end := position + 1
		symbol := text[position]
		parent := find_extendable(&nodes, text, position, last)
		next := nodes[parent].next[symbol]
		if next == 0 {
			next = node_count
			node_count += 1
			initialize_node(&nodes, next, nodes[parent].length + 2, 0)
			nodes[parent].next[symbol] = next
			if nodes[next].length == 1 {
				nodes[next].suffix_link = 0
			} else {
				suffix_parent := find_extendable(&nodes, text, position, nodes[parent].suffix_link)
				nodes[next].suffix_link = nodes[suffix_parent].next[symbol]
			}
			fail := nodes[next].suffix_link
			nodes[next].difference = nodes[next].length - nodes[fail].length
			if nodes[next].difference == nodes[fail].difference {
				nodes[next].series_link = nodes[fail].series_link
			} else {
				nodes[next].series_link = fail
			}
		}
		last = next
		best_value := MAX_TEXT + 1
		best_start := end
		node := last
		for nodes[node].length > 0 {
			start := end - nodes[nodes[node].series_link].length - nodes[node].difference
			nodes[node].series_best = dp[start]
			nodes[node].series_start = start
			fail := nodes[node].suffix_link
			if nodes[node].difference == nodes[fail].difference &&
				(nodes[fail].series_best < nodes[node].series_best ||
				 nodes[fail].series_best == nodes[node].series_best && nodes[fail].series_start < nodes[node].series_start) {
				nodes[node].series_best = nodes[fail].series_best
				nodes[node].series_start = nodes[fail].series_start
			}
			candidate := nodes[node].series_best + 1
			if candidate < best_value || candidate == best_value && nodes[node].series_start < best_start {
				best_value = candidate
				best_start = nodes[node].series_start
			}
			node = nodes[node].series_link
		}
		dp[end] = best_value
		predecessor[end] = best_start
	}

	var reverse_pieces: [MAX_TEXT]int
	piece_count := 0
	end := n
	for end > 0 {
		reverse_pieces[piece_count] = end - predecessor[end]
		piece_count += 1
		end = predecessor[end]
	}
	var words: [MAX_WORDS]i64
	word_count := 0
	words[word_count] = i64(piece_count)
	word_count += 1
	for index := 0; index < piece_count; index += 1 {
		words[word_count] = i64(reverse_pieces[piece_count - 1 - index])
		word_count += 1
	}
	bytes := word_count * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for word := 0; word < word_count; word += 1 { put_i64(output, word * 8, words[word]) }
	return i64(bytes)
}
