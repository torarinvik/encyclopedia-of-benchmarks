package bpe_tokenizer

import "core:c"

// Apply bounded byte-pair merges with first-seen tie-breaking.
@(export)
bpe_tokenizer :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 515 do return -2
	merge_count_value := values[0]
	byte_count_value := values[1]
	if merge_count_value < 0 || merge_count_value > 32 || byte_count_value < 0 || byte_count_value > 512 do return -2
	byte_count := c.size_t(byte_count_value)
	if length != byte_count + 2 do return -2
	tokens: [512]i64
	next_tokens: [512]i64
	for index: c.size_t = 0; index < byte_count; index += 1 {
		if values[index + 2] < 0 || values[index + 2] > 255 do return -2
		tokens[index] = values[index + 2]
	}
	token_count := byte_count
	for step: c.size_t = 0; step < c.size_t(merge_count_value) && token_count > 1; step += 1 {
		pair_left: [511]i64
		pair_right: [511]i64
		pair_frequency: [511]i64
		unique_pairs := c.size_t(0)
		for index: c.size_t = 0; index + 1 < token_count; index += 1 {
			pair_index := c.size_t(0)
			for pair_index < unique_pairs && (pair_left[pair_index] != tokens[index] || pair_right[pair_index] != tokens[index + 1]) {
				pair_index += 1
			}
			if pair_index == unique_pairs {
				pair_left[pair_index] = tokens[index]
				pair_right[pair_index] = tokens[index + 1]
				pair_frequency[pair_index] = 1
				unique_pairs += 1
			} else {
				pair_frequency[pair_index] += 1
			}
		}
		if unique_pairs == 0 do break
		best := c.size_t(0)
		for index: c.size_t = 1; index < unique_pairs; index += 1 {
			if pair_frequency[index] > pair_frequency[best] do best = index
		}
		if pair_frequency[best] == 1 do break
		next_count := c.size_t(0)
		index := c.size_t(0)
		for index < token_count {
			if index + 1 < token_count && tokens[index] == pair_left[best] && tokens[index + 1] == pair_right[best] {
				next_tokens[next_count] = 256 + i64(step)
				next_count += 1
				index += 2
			} else {
				next_tokens[next_count] = tokens[index]
				next_count += 1
				index += 1
			}
		}
		for item: c.size_t = 0; item < next_count; item += 1 { tokens[item] = next_tokens[item] }
		token_count = next_count
	}
	if token_count > output_capacity / 2 do return -2
	if token_count != 0 && output == nil do return -2
	for index: c.size_t = 0; index < token_count; index += 1 {
		token := u16(tokens[index])
		output[index * 2] = u8(token & 0xff)
		output[index * 2 + 1] = u8(token >> 8)
	}
	return i64(token_count)
}
