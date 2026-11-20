module palindromic_partition_series_links

const max_text = 64
const max_nodes = max_text + 2
const alphabet = 4
const max_words = max_text + 1

struct Node {
	mut:
	length int
	suffix_link int
	difference int
	series_link int
	series_best int
	series_start int
	next [alphabet]int
}

fn initialize_node(mut nodes []Node, id int, length int, suffix_link int) {
	nodes[id].length = length
	nodes[id].suffix_link = suffix_link
	nodes[id].difference = 0
	nodes[id].series_link = 1
	nodes[id].series_best = 0
	nodes[id].series_start = 0
	for symbol in 0 .. alphabet { nodes[id].next[symbol] = 0 }
}

fn find_extendable(nodes []Node, text []int, position int, start int) int {
	mut node := start
	for {
		preceding := position - 1 - nodes[node].length
		if preceding >= 0 && text[preceding] == text[position] { return node }
		node = nodes[node].suffix_link
	}
	return 0
}

fn put_word(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) }
	}
}

@[export: 'palindromic_partition_series_links']
pub fn palindromic_partition_series_links(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_text + 2 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_text { return -1 }
		 n := int(input[0])
		if length != usize(n + 1) { return -1 }
		mut text := [max_text]int{}
		for position in 0 .. n {
			symbol := input[position + 1]
			if symbol < 0 || symbol >= alphabet { return -1 }
			text[position] = int(symbol)
		}
		mut nodes := []Node{len: max_nodes, init: Node{}}
		initialize_node(mut nodes, 0, 0, 1)
		initialize_node(mut nodes, 1, -1, 1)
		mut node_count := 2
		mut last := 0
		mut dp := [max_text + 1]int{}
		mut predecessor := [max_text + 1]int{}
		for i in 0 .. max_text + 1 { dp[i] = max_text + 1 }
		dp[0] = 0
		for position in 0 .. n {
			end := position + 1
			symbol := text[position]
			parent := find_extendable(nodes, text[..n], position, last)
			mut next := nodes[parent].next[symbol]
			if next == 0 {
				next = node_count
				node_count++
				initialize_node(mut nodes, next, nodes[parent].length + 2, 0)
				nodes[parent].next[symbol] = next
				if nodes[next].length == 1 {
					nodes[next].suffix_link = 0
				} else {
					suffix_parent := find_extendable(nodes, text[..n], position, nodes[parent].suffix_link)
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
			mut best_value := max_text + 1
			mut best_start := end
			mut node := last
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
		mut reverse_pieces := [max_text]int{}
		mut piece_count := 0
		mut end := n
		for end > 0 {
			reverse_pieces[piece_count] = end - predecessor[end]
			piece_count++
			end = predecessor[end]
		}
		mut words := [max_words]i64{}
		mut word_count := 0
		words[word_count] = i64(piece_count)
		word_count++
		for index in 0 .. piece_count {
			words[word_count] = i64(reverse_pieces[piece_count - 1 - index])
			word_count++
		}
		bytes := usize(word_count * 8)
		if output == nil || capacity < bytes { return -2 }
		for word in 0 .. word_count { put_word(mut output[word * 8], 0, words[word]) }
		return i64(bytes)
	}
}
