const max_text_length = 256
const max_pattern_length = 32
const alphabet_size = 128
const transition_table_size = (max_pattern_length + 1) * alphabet_size
const max_parseable_input_length = 2 + max_text_length + max_pattern_length + 1

fn next_state(pattern &i64, pattern_length int, state int, symbol i64) int {
	unsafe {
		if state < pattern_length && symbol == pattern[state] { return state + 1 }
		mut candidate := state
		for candidate > 0 {
			if pattern[candidate - 1] == symbol {
				mut prefix_matches := true
				for index := 0; index < candidate - 1; index++ {
					if pattern[index] != pattern[state - candidate + index + 1] {
						prefix_matches = false
						break
					}
				}
				if prefix_matches { return candidate }
			}
			candidate--
		}
		return 0
	}
}

fn store_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'string_match_finite_automata']
pub fn string_match_finite_automata(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > usize(max_parseable_input_length) { return -1 }
		raw_text_length := values[0]
		raw_pattern_length := values[1]
		if raw_text_length < 0 || raw_text_length > max_text_length ||
			raw_pattern_length < 1 || raw_pattern_length > max_pattern_length ||
			length != usize(2 + raw_text_length + raw_pattern_length) { return -1 }
		text_length := int(raw_text_length)
		pattern_length := int(raw_pattern_length)
		for index := 0; index < text_length + pattern_length; index++ {
			symbol := values[2 + index]
			if symbol < 0 || symbol >= alphabet_size { return -1 }
		}

		text := &values[2]
		pattern := &values[2 + text_length]
		mut transitions := [transition_table_size]int{init: 0}
		for state := 0; state <= pattern_length; state++ {
			for symbol := 0; symbol < alphabet_size; symbol++ {
				transitions[state * alphabet_size + symbol] =
					next_state(pattern, pattern_length, state, i64(symbol))
			}
		}

		mut matches := [max_text_length]int{init: 0}
		mut match_count := 0
		mut state := 0
		for index := 0; index < text_length; index++ {
			state = transitions[state * alphabet_size + int(text[index])]
			if state == pattern_length {
				matches[match_count] = index + 1 - pattern_length
				match_count++
			}
		}

		byte_count := 4 * match_count
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for index := 0; index < match_count; index++ {
			store_i32_le(output, 4 * index, i32(matches[index]))
		}
		return i64(byte_count)
	}
}
