package string_match_finite_automata

import "core:c"

MAX_TEXT_LENGTH :: 256
MAX_PATTERN_LENGTH :: 32
ALPHABET_SIZE :: 128
TRANSITION_TABLE_SIZE :: (MAX_PATTERN_LENGTH + 1) * ALPHABET_SIZE
MAX_PARSEABLE_INPUT_LENGTH :: 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH + 1

next_state :: proc "contextless" (pattern: [^]i64, pattern_length, state: int, symbol: i64) -> int {
	if state < pattern_length && symbol == pattern[state] do return state + 1
	candidate := state
	for candidate > 0 {
		if pattern[candidate - 1] == symbol {
			prefix_matches := true
			for index := 0; index < candidate - 1; index += 1 {
				if pattern[index] != pattern[state - candidate + index + 1] {
					prefix_matches = false
					break
				}
			}
			if prefix_matches do return candidate
		}
		candidate -= 1
	}
	return 0
}

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> u32(byte * 8))
	}
}

@(export)
string_match_finite_automata :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	raw_text_length := values[0]
	raw_pattern_length := values[1]
	if raw_text_length < 0 || raw_text_length > MAX_TEXT_LENGTH ||
		raw_pattern_length < 1 || raw_pattern_length > MAX_PATTERN_LENGTH ||
		length != c.size_t(2 + raw_text_length + raw_pattern_length) do return -1
	text_length := int(raw_text_length)
	pattern_length := int(raw_pattern_length)
	for index := 0; index < text_length + pattern_length; index += 1 {
		symbol := values[2 + index]
		if symbol < 0 || symbol >= ALPHABET_SIZE do return -1
	}

	text := &values[2]
	pattern := &values[2 + text_length]
	transitions: [TRANSITION_TABLE_SIZE]int
	for state := 0; state <= pattern_length; state += 1 {
		for symbol := 0; symbol < ALPHABET_SIZE; symbol += 1 {
			transitions[state * ALPHABET_SIZE + symbol] =
				next_state(pattern, pattern_length, state, i64(symbol))
		}
	}

	matches: [MAX_TEXT_LENGTH]int
	match_count := 0
	state := 0
	for index := 0; index < text_length; index += 1 {
		state = transitions[state * ALPHABET_SIZE + int(text[index])]
		if state == pattern_length {
			matches[match_count] = index + 1 - pattern_length
			match_count += 1
		}
	}

	byte_count := 4 * match_count
	if output == nil || output_capacity < c.size_t(byte_count) do return -2
	for index := 0; index < match_count; index += 1 {
		store_i32_le(output, 4 * index, i32(matches[index]))
	}
	return i64(byte_count)
}
