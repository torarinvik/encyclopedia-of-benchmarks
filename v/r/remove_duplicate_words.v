module main

const max_input_length = 4096
const max_words = 2049

fn is_ascii_whitespace(byte i64) bool {
	return byte == 32 || (byte >= 9 && byte <= 13)
}

@[export: 'remove_duplicate_words']
pub fn remove_duplicate_words(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length + 1 { return -1 }
		if input[0] < 0 || input[0] > max_input_length { return -1 }
		text_length := int(input[0])
		if int(length) != text_length + 1 { return -1 }
		for index in 0 .. text_length {
			if input[index + 1] < 0 || input[index + 1] > 127 { return -1 }
		}

		mut starts := []int{len: max_words, init: 0}
		mut word_lengths := []int{len: max_words, init: 0}
		mut word_count := 0
		mut token_start := 0
		mut output_length := 0
		for boundary in 0 .. text_length + 1 {
			if boundary < text_length && !is_ascii_whitespace(input[boundary + 1]) { continue }
			word_length := boundary - token_start
			mut duplicate := false
			for previous in 0 .. word_count {
				if word_lengths[previous] != word_length { continue }
				mut offset := 0
				for offset < word_length && input[1 + starts[previous] + offset] == input[1 + token_start + offset] { offset++ }
				if offset == word_length { duplicate = true; break }
			}
			if !duplicate {
				if word_count == max_words { return -1 }
				starts[word_count] = token_start
				word_lengths[word_count] = word_length
				if word_count > 0 { output_length++ }
				output_length += word_length
				word_count++
			}
			if boundary < text_length { token_start = boundary + 1 }
		}
		if usize(output_length) > output_capacity || (output_length > 0 && output == nil) { return -2 }

		mut written := 0
		for word in 0 .. word_count {
			if word > 0 { output[written] = 32; written++ }
			for offset in 0 .. word_lengths[word] {
				output[written] = u8(input[1 + starts[word] + offset])
				written++
			}
		}
		return i64(written)
	}
}
