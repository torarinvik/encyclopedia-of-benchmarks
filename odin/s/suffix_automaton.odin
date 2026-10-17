package suffix_automaton

import "core:c"

MAX_TEXT :: 256
MAX_QUERIES :: 128
MAX_STATES :: 2 * MAX_TEXT
MAX_INPUT_LENGTH :: 33283
MAX_VALID_INPUT_LENGTH :: 33282
ALPHABET :: 128

Sam_State :: struct {
	length: int,
	link: i32,
	next: [ALPHABET]i32,
}

initialize_state :: proc(state: ^Sam_State) {
	state.length = 0
	state.link = -1
	for symbol in 0..<ALPHABET {
		state.next[symbol] = -1
	}
}

build_automaton :: proc(states: [^]Sam_State, text: [^]int, text_length: int) -> int {
	initialize_state(&states[0])
	state_count := 1
	last := 0
	for position in 0..<text_length {
		symbol := text[position]
		current := state_count
		state_count += 1
		initialize_state(&states[current])
		states[current].length = states[last].length + 1
		previous := i32(last)
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
				state_count += 1
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

find_state :: proc(states: [^]Sam_State, pattern: [^]int, pattern_length: int) -> int {
	current := 0
	for position in 0..<pattern_length {
		next_state := states[current].next[pattern[position]]
		if next_state == -1 do return -1
		current = int(next_state)
	}
	return current
}

count_occurrences :: proc(states: [^]Sam_State, state_count: int, text: [^]int,
		text_length: int, pattern: [^]int, pattern_length: int) -> i64 {
	pattern_state := find_state(states, pattern, pattern_length)
	if pattern_state < 0 do return 0
	occurrences: [MAX_STATES]i64
	by_length: [MAX_TEXT + 1]int
	order: [MAX_STATES]int
	for state in 0..<state_count {
		by_length[states[state].length] += 1
	}
	for length := 1; length <= text_length; length += 1 {
		by_length[length] += by_length[length - 1]
	}
	for state := state_count - 1; state >= 0; state -= 1 {
		state_length := states[state].length
		by_length[state_length] -= 1
		order[by_length[state_length]] = state
	}
	last := 0
	for position in 0..<text_length {
		last = int(states[last].next[text[position]])
		occurrences[last] = 1
	}
	for index := state_count - 1; index >= 0; index -= 1 {
		state := order[index]
		link := states[state].link
		if link != -1 {
			occurrences[int(link)] += occurrences[state]
		}
	}
	return occurrences[pattern_state]
}

count_distinct_substrings :: proc(states: [^]Sam_State, state_count: int) -> i64 {
	total: i64 = 0
	for state in 1..<state_count {
		link := int(states[state].link)
		total += i64(states[state].length - states[link].length)
	}
	return total
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte in 0..<8 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
suffix_automaton :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	input_length := int(length)
	if input[0] < 1 || input[0] > i64(MAX_TEXT) do return -1
	text_length := int(input[0])
	query_count_index := text_length + 1
	if input_length <= query_count_index || input[query_count_index] < 0 || input[query_count_index] > i64(MAX_QUERIES) do return -1
	query_count := int(input[query_count_index])
	if input_length > MAX_VALID_INPUT_LENGTH do return -1
	text: [MAX_TEXT]int
	for position in 0..<text_length {
		symbol := input[position + 1]
		if symbol < 0 || symbol >= i64(ALPHABET) do return -1
		text[position] = int(symbol)
	}
	states: [MAX_STATES]Sam_State
	state_count := build_automaton(&states[0], &text[0], text_length)
	results: [MAX_QUERIES]i64
	opcodes: [MAX_QUERIES]u8
	cursor := query_count_index + 1
	for query in 0..<query_count {
		if cursor + 1 >= input_length do return -1
		opcode_value := input[cursor]
		cursor += 1
		pattern_length_value := input[cursor]
		cursor += 1
		if opcode_value < 0 || opcode_value > 2 || pattern_length_value < 0 || pattern_length_value > i64(MAX_TEXT) do return -1
		opcode := int(opcode_value)
		pattern_length := int(pattern_length_value)
		if opcode == 2 && pattern_length != 0 do return -1
		if pattern_length > input_length - cursor do return -1
		pattern: [MAX_TEXT]int
		for position in 0..<pattern_length {
			symbol := input[cursor]
			cursor += 1
			if symbol < 0 || symbol >= i64(ALPHABET) do return -1
			pattern[position] = int(symbol)
		}
		opcodes[query] = u8(opcode)
		if opcode == 0 {
			if find_state(&states[0], &pattern[0], pattern_length) >= 0 {
				results[query] = 1
			}
		} else if opcode == 1 {
			results[query] = count_occurrences(&states[0], state_count, &text[0], text_length, &pattern[0], pattern_length)
		} else {
			results[query] = count_distinct_substrings(&states[0], state_count)
		}
	}
	if cursor != input_length do return -1
	output_bytes := query_count * 9
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for query in 0..<query_count {
		output[query * 9] = opcodes[query]
		store_i64_le(output, query * 9 + 1, results[query])
	}
	return i64(output_bytes)
}
