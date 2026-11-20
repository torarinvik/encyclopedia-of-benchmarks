package generalized_suffix_automaton_union

import "core:c"

MIN_STRINGS :: 2
MAX_STRINGS :: 8
MAX_TOTAL_SYMBOLS :: 24
MAX_TRIE_NODES :: MAX_TOTAL_SYMBOLS + 1
MAX_STATES :: 49
ALPHABET_SIZE :: 4
MAX_PARSEABLE_LENGTH :: 34

Gsa_State :: struct {
	length: int,
	link: int,
	next: [ALPHABET_SIZE]int,
}

@(export)
generalized_suffix_automaton_union :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	if input[0] < MIN_STRINGS || input[0] > MAX_STRINGS do return -1
	string_count := int(input[0])

	states: [MAX_STATES]Gsa_State = {}
	for state in 0..<MAX_STATES { states[state].link = -1 }
	trie_next: [MAX_TRIE_NODES][ALPHABET_SIZE]int = {}
	trie_parent: [MAX_TRIE_NODES]int = {}
	trie_symbol: [MAX_TRIE_NODES]int = {}

	trie_node_count := 1
	total_symbols := 0
	cursor := 1
	for _ in 0..<string_count {
		if cursor >= int(length) do return -1
		string_length_value := input[cursor]
		cursor += 1
		if string_length_value < 0 || string_length_value > 8 do return -1
		string_length := int(string_length_value)
		if total_symbols + string_length > MAX_TOTAL_SYMBOLS || string_length > int(length)-cursor do return -1
		total_symbols += string_length

		node := 0
		for offset in 0..<string_length {
			symbol_value := input[cursor+offset]
			if symbol_value < 0 || symbol_value >= ALPHABET_SIZE do return -1
			symbol := int(symbol_value)
			child := trie_next[node][symbol]
			if child == 0 {
				if trie_node_count >= MAX_TRIE_NODES do return -1
				child = trie_node_count
				trie_node_count += 1
				trie_next[node][symbol] = child
				states[node].next[symbol] = child
				trie_parent[child] = node
				trie_symbol[child] = symbol
			}
			node = child
		}
		cursor += string_length
	}
	if cursor != int(length) do return -1

	state_count := trie_node_count
	queue: [MAX_TRIE_NODES]int = {}
	queue_head := 0
	queue_tail := 0
	for symbol in 0..<ALPHABET_SIZE {
		child := trie_next[0][symbol]
		if child != 0 {
			queue[queue_tail] = child
			queue_tail += 1
		}
	}

	for queue_head < queue_tail {
		current := queue[queue_head]
		queue_head += 1
		parent := trie_parent[current]
		symbol := trie_symbol[current]
		states[current].length = states[parent].length + 1

		previous := states[parent].link
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
				if state_count >= MAX_STATES do return -1
				clone := state_count
				state_count += 1
				states[clone].length = states[previous].length + 1
				states[clone].link = states[next_state].link
				for character in 0..<ALPHABET_SIZE {
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

		for character in 0..<ALPHABET_SIZE {
			child := trie_next[current][character]
			if child != 0 {
				queue[queue_tail] = child
				queue_tail += 1
			}
		}
	}

	distinct_count: i64 = 0
	for state in 1..<state_count {
		distinct_count += i64(states[state].length - states[states[state].link].length)
	}
	return distinct_count
}
