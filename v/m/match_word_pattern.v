module match_word_pattern

const max_pattern_length = 8
const max_text_length = 32
const max_input_length = 43

fn match_word_pattern_search(input &i64, pattern_length int, text_start int, text_length int,
                            pattern_index int, text_index int,
                            mapped_start &int, mapped_length &int) bool {
	unsafe {
		if pattern_index == pattern_length { return text_index == text_length }
		if text_index == text_length { return false }

		symbol := int(input[2 + pattern_index])
		known_length := mapped_length[symbol]
		if known_length != 0 {
			if known_length > text_length - text_index { return false }
			for offset in 0 .. known_length {
				if input[text_start + mapped_start[symbol] + offset] != input[text_start + text_index + offset] {
					return false
				}
			}
			return match_word_pattern_search(input, pattern_length, text_start, text_length,
				pattern_index + 1, text_index + known_length, mapped_start, mapped_length)
		}

		for ending in text_index + 1 .. text_length + 1 {
			candidate_length := ending - text_index
			mut already_used := false
			for other_index in 0 .. pattern_index {
				other := int(input[2 + other_index])
				if other == symbol { continue }
				if mapped_length[other] == candidate_length {
					mut equal := true
					for offset in 0 .. candidate_length {
						if input[text_start + mapped_start[other] + offset] != input[text_start + text_index + offset] {
							equal = false
							break
						}
					}
					if equal {
						already_used = true
						break
					}
				}
			}
			if already_used { continue }

			mapped_start[symbol] = text_index
			mapped_length[symbol] = candidate_length
			if match_word_pattern_search(input, pattern_length, text_start, text_length,
				pattern_index + 1, ending, mapped_start, mapped_length) {
				return true
			}
			mapped_length[symbol] = 0
		}
		return false
	}
}

@[export: 'match_word_pattern']
pub fn match_word_pattern(input &i64, input_length usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_pattern_length
			|| input[1] < 0 || input[1] > max_text_length { return -1 }
		pattern_length := int(input[0])
		text_length := int(input[1])
		if input_length != usize(2 + pattern_length + text_length) { return -1 }
		for index in 0 .. pattern_length + text_length {
			if input[2 + index] < 0 || input[2 + index] > 127 { return -1 }
		}

		mut mapped_start := [128]int{}
		mut mapped_length := [128]int{}
		if match_word_pattern_search(input, pattern_length, 2 + pattern_length, text_length,
			0, 0, &mapped_start[0], &mapped_length[0]) {
			return 1
		}
		return 0
	}
}
