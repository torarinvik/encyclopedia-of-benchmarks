module parameterized_pattern_matching_kmp

const max_text = 64
const max_pattern = 16
const max_alphabet = 16
const max_parseable_input = 84
const max_output_bytes = 520

fn store_word(mut output []u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[word * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn pattern_pair(pattern []i64, previous []int, current int, prefix_position int) bool {
	prior := previous[current]
	if prior < 0 || current-prior > prefix_position { return previous[prefix_position] < 0 }
	distance := current - prior
	return pattern[prefix_position] == pattern[prefix_position-distance]
}

fn text_pair(text []i64, text_position int, pattern_position int,
	previous []int, last_text []int) bool {
	prior := previous[pattern_position]
	symbol := int(text[text_position])
	if prior < 0 { return last_text[symbol] < text_position-pattern_position }
	distance := pattern_position - prior
	return text[text_position] == text[text_position-distance]
}

@[export: 'parameterized_pattern_matching_kmp']
pub fn parameterized_pattern_matching_kmp(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_input { return -1 }
		n_value, m_value, alphabet_value := input[0], input[1], input[2]
		if n_value < 0 || n_value > max_text || m_value < 1 || m_value > max_pattern ||
			alphabet_value < 1 || alphabet_value > max_alphabet { return -1 }
		n, m, alphabet_size := int(n_value), int(m_value), int(alphabet_value)
		if length != usize(3 + n + m) { return -1 }
		mut text := [max_text]i64{init: 0}
		mut pattern := [max_pattern]i64{init: 0}
		for index in 0 .. n + m {
			symbol := input[3 + index]
			if symbol < 0 || symbol >= i64(alphabet_size) { return -1 }
			if index < n { text[index] = symbol } else { pattern[index-n] = symbol }
		}
		mut previous := [max_pattern]int{init: -1}
		mut last_pattern := [max_alphabet]int{init: -1}
		for index in 0 .. m {
			symbol := int(pattern[index])
			previous[index] = last_pattern[symbol]
			last_pattern[symbol] = index
		}
		mut failure := [max_pattern]int{init: 0}
		for current in 1 .. m {
			mut matched := failure[current-1]
			for matched > 0 && !pattern_pair(pattern[..], previous[..], current, matched) {
				matched = failure[matched-1]
			}
			if pattern_pair(pattern[..], previous[..], current, matched) { matched++ }
			failure[current] = matched
		}
		mut last_text := [max_alphabet]int{init: -1}
		mut matches := [max_text]i64{init: 0}
		mut match_count := 0
		mut matched := 0
		if m <= n {
			for text_position in 0 .. n {
				for {
					if text_pair(text[..], text_position, matched, previous[..], last_text[..]) {
						matched++
						if matched == m {
							matches[match_count] = i64(text_position + 1 - m)
							match_count++
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
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		store_word(mut staged[..], 0, i64(match_count))
		for index in 0 .. match_count { store_word(mut staged[..], index+1, matches[index]) }
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
