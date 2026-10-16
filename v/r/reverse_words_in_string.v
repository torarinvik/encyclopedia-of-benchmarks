module main

const max_parseable_input_length = 258

fn is_trim_byte(value i64) bool { return value >= 0 && value <= 32 }
fn is_split_space(value i64) bool { return value == 32 || (value >= 9 && value <= 13) }

@[export: 'reverse_words_in_string']
pub fn reverse_words_in_string(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > max_parseable_input_length { return -1 }
		if input[0] < 0 || input[0] > 256 || length != usize(input[0]) + 1 { return -1 }
		text_length := int(input[0])
		for i in 0 .. text_length {
			if input[i + 1] < 0 || input[i + 1] > 127 { return -1 }
		}

		mut start := 0
		mut end := text_length
		for start < end && is_trim_byte(input[start + 1]) { start++ }
		for end > start && is_trim_byte(input[end]) { end-- }

		mut output_length := 0
		mut word_count := 0
		mut position := start
		for position < end {
			for position < end && is_split_space(input[position + 1]) { position++ }
			if position < end {
				token_start := position
				for position < end && !is_split_space(input[position + 1]) { position++ }
				output_length += position - token_start
				if word_count > 0 { output_length++ }
				word_count++
			}
		}
		if capacity < output_length || (output_length > 0 && output == nil) { return -2 }

		mut written := 0
		mut emitted := 0
		position = end
		for position > start {
			for position > start && is_split_space(input[position]) { position-- }
			if position > start {
				token_end := position
				for position > start && !is_split_space(input[position]) { position-- }
				token_start := position
				if emitted > 0 { output[written] = u8(32); written++ }
				for i in token_start .. token_end {
					output[written] = u8(input[i + 1])
					written++
				}
				emitted++
			}
		}
		return i64(written)
	}
}
