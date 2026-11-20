module maximum_matching_word_segmentation

const max_text = 64
const max_words = 16
const max_word_length = 8
const max_parseable_length = 211

@[export: 'maximum_matching_word_segmentation']
pub fn maximum_matching_word_segmentation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_length { return -1 }
	unsafe {
		text_length_value := input[0]
		word_count_value := input[1]
		if text_length_value < 0 || text_length_value > max_text || word_count_value < 0 || word_count_value > max_words { return -1 }
		text_length, word_count := int(text_length_value), int(word_count_value)
		if length < usize(2 + text_length) { return -1 }
		for position in 0 .. text_length {
			if input[position + 2] < 97 || input[position + 2] > 122 { return -1 }
		}
		mut word_offsets := [max_words]usize{}
		mut word_lengths := [max_words]usize{}
		mut cursor := 2 + text_length
		for word in 0 .. word_count {
			if cursor >= int(length) { return -1 }
			word_length_value := input[cursor]
			cursor++
			if word_length_value < 1 || word_length_value > max_word_length { return -1 }
			word_length := int(word_length_value)
			if word_length > int(length) - cursor { return -1 }
			word_offsets[word] = usize(cursor)
			word_lengths[word] = usize(word_length)
			for offset in 0 .. word_length {
				if input[cursor + offset] < 97 || input[cursor + offset] > 122 { return -1 }
			}
			cursor += word_length
		}
		if cursor != int(length) { return -1 }

		mut token_ids := [max_text]u8{}
		mut token_count := 0
		mut position := 0
		for position < text_length {
			mut best_length := 0
			mut best_id := u8(0)
			for word in 0 .. word_count {
				candidate_length := int(word_lengths[word])
				if candidate_length <= best_length || candidate_length > text_length - position { continue }
				mut offset := 0
				for offset < candidate_length && input[int(word_offsets[word]) + offset] == input[2 + position + offset] { offset++ }
				if offset == candidate_length {
					best_length = candidate_length
					best_id = u8(word + 1)
				}
			}
			token_ids[token_count] = best_id
			token_count++
			if best_length == 0 {
				position++
			} else {
				position += best_length
			}
		}
		output_length := token_count + 1
		if output == nil || capacity < usize(output_length) { return -2 }
		output[0] = u8(token_count)
		for token in 0 .. token_count { output[token + 1] = token_ids[token] }
		return i64(output_length)
	}
}
