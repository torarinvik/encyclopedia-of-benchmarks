module suffix_automaton

const max_text = 256
const max_queries = 128
const max_states = 2 * max_text
const max_input_length = 33283
const max_valid_input_length = 33282
const alphabet = 128

struct SamState {
mut:
	length int
	link i32
	next [alphabet]i32
}

fn initialize_state(mut state SamState) {
	state.length = 0
	state.link = -1
	for symbol in 0 .. alphabet {
		state.next[symbol] = -1
	}
}

fn build_automaton(mut states [max_states]SamState, text [max_text]int, text_length int) int {
	initialize_state(mut states[0])
	mut state_count := 1
	mut last := 0
	for position in 0 .. text_length {
		symbol := text[position]
		current := state_count
		state_count++
		initialize_state(mut states[current])
		states[current].length = states[last].length + 1
		mut previous := i32(last)
		for previous != -1 && states[int(previous)].next[symbol] == -1 {
			states[int(previous)].next[symbol] = i32(current)
			previous = states[int(previous)].link
		}
		if previous == -1 {
			states[current].link = 0
		} else {
			next_state := int(states[int(previous)].next[symbol])
			if states[int(previous)].length + 1 == states[next_state].length {
				states[current].link = i32(next_state)
			} else {
				clone := state_count
				state_count++
				states[clone] = states[next_state]
				states[clone].length = states[int(previous)].length + 1
				for previous != -1 && states[int(previous)].next[symbol] == i32(next_state) {
					states[int(previous)].next[symbol] = i32(clone)
					previous = states[int(previous)].link
				}
				states[next_state].link = i32(clone)
				states[current].link = i32(clone)
			}
		}
		last = current
	}
	return state_count
}

fn find_state(mut states [max_states]SamState, pattern [max_text]int, pattern_length int) int {
	mut current := 0
	for position in 0 .. pattern_length {
		next_state := states[current].next[pattern[position]]
		if next_state == -1 { return -1 }
		current = int(next_state)
	}
	return current
}

fn count_occurrences(mut states [max_states]SamState, state_count int, text [max_text]int,
	text_length int, pattern [max_text]int, pattern_length int) i64 {
	pattern_state := find_state(mut states, pattern, pattern_length)
	if pattern_state < 0 { return 0 }
	mut occurrences := [max_states]i64{}
	mut by_length := [max_text + 1]int{}
	mut order := [max_states]int{}
	for state in 0 .. state_count { by_length[states[state].length]++ }
	for length in 1 .. text_length + 1 { by_length[length] += by_length[length - 1] }
	for state := state_count - 1; state >= 0; state-- {
		state_length := states[state].length
		by_length[state_length]--
		order[by_length[state_length]] = state
	}
	mut last := 0
	for position in 0 .. text_length {
		last = int(states[last].next[text[position]])
		occurrences[last] = 1
	}
	for index := state_count - 1; index >= 0; index-- {
		state := order[index]
		link := states[state].link
		if link != -1 { occurrences[int(link)] += occurrences[state] }
	}
	return occurrences[pattern_state]
}

fn count_distinct_substrings(mut states [max_states]SamState, state_count int) i64 {
	mut total := i64(0)
	for state in 1 .. state_count {
		link := int(states[state].link)
		total += i64(states[state].length - states[link].length)
	}
	return total
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) }
	}
}

@[export: 'suffix_automaton']
pub fn suffix_automaton(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input_length) { return -1 }
	unsafe {
		input_length := int(length)
		if input[0] < 1 || input[0] > i64(max_text) { return -1 }
		text_length := int(input[0])
		query_count_index := text_length + 1
		if input_length <= query_count_index || input[query_count_index] < 0 || input[query_count_index] > i64(max_queries) { return -1 }
		query_count := int(input[query_count_index])
		if input_length > max_valid_input_length { return -1 }
		mut text := [max_text]int{}
		for position in 0 .. text_length {
			symbol := input[position + 1]
			if symbol < 0 || symbol >= i64(alphabet) { return -1 }
			text[position] = int(symbol)
		}
		mut states := [max_states]SamState{}
		state_count := build_automaton(mut states, text, text_length)
		mut results := [max_queries]i64{}
		mut opcodes := [max_queries]u8{}
		mut cursor := query_count_index + 1
		for query in 0 .. query_count {
			if cursor + 1 >= input_length { return -1 }
			opcode_value := input[cursor]
			cursor++
			pattern_length_value := input[cursor]
			cursor++
			if opcode_value < 0 || opcode_value > 2 || pattern_length_value < 0 || pattern_length_value > i64(max_text) { return -1 }
			opcode := int(opcode_value)
			pattern_length := int(pattern_length_value)
			if opcode == 2 && pattern_length != 0 { return -1 }
			if pattern_length > input_length - cursor { return -1 }
			mut pattern := [max_text]int{}
			for position in 0 .. pattern_length {
				symbol := input[cursor]
				cursor++
				if symbol < 0 || symbol >= i64(alphabet) { return -1 }
				pattern[position] = int(symbol)
			}
			opcodes[query] = u8(opcode)
			if opcode == 0 {
				if find_state(mut states, pattern, pattern_length) >= 0 { results[query] = 1 }
			} else if opcode == 1 {
				results[query] = count_occurrences(mut states, state_count, text, text_length, pattern, pattern_length)
			} else {
				results[query] = count_distinct_substrings(mut states, state_count)
			}
		}
		if cursor != input_length { return -1 }
		output_bytes := query_count * 9
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for query in 0 .. query_count {
			output[query * 9] = opcodes[query]
			store_i64_le(mut output, query * 9 + 1, results[query])
		}
		return i64(output_bytes)
	}
}
