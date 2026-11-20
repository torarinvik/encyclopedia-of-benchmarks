package parameterized_pattern_matching_kmp

import "core:c"

MAX_TEXT :: 64
MAX_PATTERN :: 16
MAX_ALPHABET :: 16
MAX_PARSEABLE_INPUT :: 84
MAX_OUTPUT_BYTES :: 520

store_word :: proc(output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[word * 8 + byte] = u8(bits & 255)
		bits >>= 8
	}
}

pattern_pair :: proc(pattern: []i64, previous: []int,
	current, prefix_position: int) -> bool {
	prior := previous[current]
	if prior < 0 || current-prior > prefix_position { return previous[prefix_position] < 0 }
	distance := current - prior
	return pattern[prefix_position] == pattern[prefix_position-distance]
}

text_pair :: proc(text: []i64, text_position, pattern_position: int,
	previous: []int, last_text: []int) -> bool {
	prior := previous[pattern_position]
	symbol := int(text[text_position])
	if prior < 0 { return last_text[symbol] < text_position-pattern_position }
	distance := pattern_position - prior
	return text[text_position] == text[text_position-distance]
}

@(export)
parameterized_pattern_matching_kmp :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT do return -1
	n_value, m_value, alphabet_value := input[0], input[1], input[2]
	if n_value < 0 || n_value > MAX_TEXT || m_value < 1 || m_value > MAX_PATTERN ||
		alphabet_value < 1 || alphabet_value > MAX_ALPHABET do return -1
	n, m, alphabet_size := int(n_value), int(m_value), int(alphabet_value)
	if length != c.size_t(3 + n + m) do return -1
	text: [MAX_TEXT]i64
	pattern: [MAX_PATTERN]i64
	for index := 0; index < n+m; index += 1 {
		symbol := input[3 + index]
		if symbol < 0 || symbol >= i64(alphabet_size) do return -1
		if index < n { text[index] = symbol } else { pattern[index-n] = symbol }
	}

	previous: [MAX_PATTERN]int
	last_pattern: [MAX_ALPHABET]int
	for symbol := 0; symbol < MAX_ALPHABET; symbol += 1 { last_pattern[symbol] = -1 }
	for index := 0; index < m; index += 1 {
		symbol := int(pattern[index])
		previous[index] = last_pattern[symbol]
		last_pattern[symbol] = index
	}
	failure: [MAX_PATTERN]int
	for current := 1; current < m; current += 1 {
		matched := failure[current-1]
		for matched > 0 && !pattern_pair(pattern[:], previous[:], current, matched) {
			matched = failure[matched-1]
		}
		if pattern_pair(pattern[:], previous[:], current, matched) { matched += 1 }
		failure[current] = matched
	}

	last_text: [MAX_ALPHABET]int
	for symbol := 0; symbol < MAX_ALPHABET; symbol += 1 { last_text[symbol] = -1 }
	matches: [MAX_TEXT]i64
	match_count, matched := 0, 0
	if m <= n {
		for text_position := 0; text_position < n; text_position += 1 {
			for {
				if text_pair(text[:], text_position, matched, previous[:], last_text[:]) {
					matched += 1
					if matched == m {
						matches[match_count] = i64(text_position + 1 - m)
						match_count += 1
						matched = failure[m-1]
					}
					break
				}
				if matched == 0 { break }
				matched = failure[matched-1]
			}
			last_text[int(text[text_position])] = text_position
		}
	}

	output_bytes := 8 * (match_count + 1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	store_word(&staged[0], 0, i64(match_count))
	for index := 0; index < match_count; index += 1 {
		store_word(&staged[0], index+1, matches[index])
	}
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
