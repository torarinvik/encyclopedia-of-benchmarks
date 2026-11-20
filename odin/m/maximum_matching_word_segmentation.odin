package maximum_matching_word_segmentation

import "core:c"

MAX_TEXT :: 64
MAX_WORDS :: 16
MAX_WORD_LENGTH :: 8
MAX_PARSEABLE_LENGTH :: 211

@(export)
maximum_matching_word_segmentation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	text_length_value, word_count_value := input[0], input[1]
	if text_length_value < 0 || text_length_value > MAX_TEXT || word_count_value < 0 || word_count_value > MAX_WORDS do return -1
	text_length, word_count := int(text_length_value), int(word_count_value)
	if int(length) < 2+text_length do return -1
	for position in 0..<text_length {
		if input[position+2] < 97 || input[position+2] > 122 do return -1
	}

	var word_offsets: [MAX_WORDS]usize
	var word_lengths: [MAX_WORDS]usize
	cursor := 2+text_length
	for word in 0..<word_count {
		if cursor >= int(length) do return -1
		word_length_value := input[cursor]
		cursor += 1
		if word_length_value < 1 || word_length_value > MAX_WORD_LENGTH do return -1
		word_length := int(word_length_value)
		if word_length > int(length)-cursor do return -1
		word_offsets[word] = usize(cursor)
		word_lengths[word] = usize(word_length)
		for offset in 0..<word_length {
			if input[cursor+offset] < 97 || input[cursor+offset] > 122 do return -1
		}
		cursor += word_length
	}
	if cursor != int(length) do return -1

	var token_ids: [MAX_TEXT]u8
	token_count := 0
	position := 0
	for position < text_length {
		best_length := 0
		best_id := u8(0)
		for word in 0..<word_count {
			candidate_length := int(word_lengths[word])
			if candidate_length <= best_length || candidate_length > text_length-position do continue
			offset := 0
			for offset < candidate_length && input[int(word_offsets[word])+offset] == input[2+position+offset] { offset += 1 }
			if offset == candidate_length {
				best_length = candidate_length
				best_id = u8(word+1)
			}
		}
		token_ids[token_count] = best_id
		token_count += 1
		step := best_length
		if step == 0 do step = 1
		position += step
	}

	output_length := token_count+1
	if output == nil || capacity < c.size_t(output_length) do return -2
	output[0] = u8(token_count)
	for token in 0..<token_count { output[token+1] = token_ids[token] }
	return i64(output_length)
}
