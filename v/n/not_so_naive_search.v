module not_so_naive_search

const max_text = 512
const min_pattern = 2
const max_pattern = 64
const max_input = 578

@[export: 'not_so_naive_search']
pub fn not_so_naive_search(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > max_input { return -2 }
		raw_text := values[0]
		raw_pattern := values[1]
		if raw_text < 0 || raw_text > max_text || raw_pattern < min_pattern || raw_pattern > max_pattern { return -2 }
		text_length := int(raw_text)
		pattern_length := int(raw_pattern)
		if length != usize(2 + text_length + pattern_length) { return -2 }
		pattern_start := 2 + text_length
		for i := 0; i < text_length + pattern_length; i++ {
			byte := values[2 + i]
			if byte < 0 || byte > 127 { return -2 }
		}
		if pattern_length > text_length { return -1 }

		same_prefix := values[pattern_start] == values[pattern_start + 1]
		mismatch_shift := if same_prefix { 2 } else { 1 }
		post_check_shift := if same_prefix { 1 } else { 2 }
		mut position := 0
		last_start := text_length - pattern_length
		for position <= last_start {
			if values[pattern_start + 1] != values[2 + position + 1] {
				position += mismatch_shift
				continue
			}
			mut pattern_index := 2
			for pattern_index < pattern_length && values[pattern_start + pattern_index] == values[2 + position + pattern_index] {
				pattern_index++
			}
			if pattern_index == pattern_length && values[pattern_start] == values[2 + position] {
				return i64(position)
			}
			position += post_check_shift
		}
		return -1
	}
}
