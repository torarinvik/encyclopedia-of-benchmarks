module generalized_suffix_automaton_union

const min_strings = 2
const max_strings = 8
const max_total_symbols = 24
const max_trie_nodes = max_total_symbols + 1
const max_states = 49
const alphabet_size = 4
const max_parseable_length = 34

struct GsaState {
mut:
	length int
	link int
	next [4]int
}

@[export: 'generalized_suffix_automaton_union']
pub fn generalized_suffix_automaton_union(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		string_count_value := input[0]
		if string_count_value < min_strings || string_count_value > max_strings { return -1 }
		string_count := int(string_count_value)

		mut states := [max_states]GsaState{}
		for state in 0 .. max_states { states[state].link = -1 }
		mut trie_next := [max_trie_nodes][alphabet_size]int{}
		mut trie_parent := [max_trie_nodes]int{}
		mut trie_symbol := [max_trie_nodes]int{}
		mut trie_node_count := 1
		mut total_symbols := 0
		mut cursor := 1

		for _ in 0 .. string_count {
			if cursor >= int(length) { return -1 }
			string_length_value := input[cursor]
			cursor++
			if string_length_value < 0 || string_length_value > 8 { return -1 }
			string_length := int(string_length_value)
			if total_symbols + string_length > max_total_symbols || string_length > int(length) - cursor {
				return -1
			}
			total_symbols += string_length

			mut node := 0
			for offset in 0 .. string_length {
				symbol_value := input[cursor + offset]
				if symbol_value < 0 || symbol_value >= alphabet_size { return -1 }
				symbol := int(symbol_value)
				mut child := trie_next[node][symbol]
				if child == 0 {
					if trie_node_count >= max_trie_nodes { return -1 }
					child = trie_node_count
					trie_node_count++
					trie_next[node][symbol] = child
					states[node].next[symbol] = child
					trie_parent[child] = node
					trie_symbol[child] = symbol
				}
				node = child
			}
			cursor += string_length
		}
		if cursor != int(length) { return -1 }

		mut state_count := trie_node_count
		mut queue := [max_trie_nodes]int{}
		mut queue_head := 0
		mut queue_tail := 0
		for symbol in 0 .. alphabet_size {
			child := trie_next[0][symbol]
			if child != 0 {
				queue[queue_tail] = child
				queue_tail++
			}
		}

		for queue_head < queue_tail {
			current := queue[queue_head]
			queue_head++
			parent := trie_parent[current]
			symbol := trie_symbol[current]
			states[current].length = states[parent].length + 1

			mut previous := states[parent].link
			for previous != -1 && states[previous].next[symbol] == 0 {
				states[previous].next[symbol] = current
				previous = states[previous].link
			}
			if previous == -1 {
				states[current].link = 0
			} else {
				next_state := states[previous].next[symbol]
				if states[previous].length + 1 == states[next_state].length {
					states[current].link = next_state
				} else {
					if state_count >= max_states { return -1 }
					clone := state_count
					state_count++
					states[clone].length = states[previous].length + 1
					states[clone].link = states[next_state].link
					for character in 0 .. alphabet_size {
						destination := states[next_state].next[character]
						if destination != 0 && states[destination].length > 0 {
							states[clone].next[character] = destination
						}
					}
					for previous != -1 && states[previous].next[symbol] == next_state {
						states[previous].next[symbol] = clone
						previous = states[previous].link
					}
					states[next_state].link = clone
					states[current].link = clone
				}
			}

			for character in 0 .. alphabet_size {
				child := trie_next[current][character]
				if child != 0 {
					queue[queue_tail] = child
					queue_tail++
				}
			}
		}

		mut distinct_count := i64(0)
		for state in 1 .. state_count {
			distinct_count += i64(states[state].length - states[states[state].link].length)
		}
		return distinct_count
	}
}
