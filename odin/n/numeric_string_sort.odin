package numeric_string_sort

import "core:c"

MAX_ITEMS :: 64
MAX_TOKEN_LENGTH :: 32
MAX_INPUT_LENGTH :: 2113
MAX_OUTPUT_LENGTH :: 2111

token_less :: proc(values: [^]i64, left_start, left_length: c.size_t,
                   right_start, right_length: c.size_t) -> bool {
	if left_length != right_length do return left_length < right_length
	for index := c.size_t(0); index < left_length; index += 1 {
		left := values[left_start + index]
		right := values[right_start + index]
		if left != right do return left < right
	}
	return false
}

@(export)
numeric_string_sort :: proc "c" (values: [^]i64, length: c.size_t,
                                  output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_INPUT_LENGTH + 1 do return -1
	if values[0] < 0 || values[0] > MAX_ITEMS do return -1
	count := c.size_t(values[0])
	starts: [MAX_ITEMS]c.size_t = {}
	token_lengths: [MAX_ITEMS]c.size_t = {}
	normalized_starts: [MAX_ITEMS]c.size_t = {}
	normalized_lengths: [MAX_ITEMS]c.size_t = {}
	order: [MAX_ITEMS]c.size_t = {}
	cursor := c.size_t(1)
	output_length := c.size_t(0)
	if count > 0 do output_length = count - 1

	for item := c.size_t(0); item < count; item += 1 {
		if cursor >= length do return -1
		raw_length := values[cursor]
		cursor += 1
		if raw_length < 1 || raw_length > MAX_TOKEN_LENGTH || c.size_t(raw_length) > length - cursor do return -1
		token_length := c.size_t(raw_length)
		start := cursor
		for offset := c.size_t(0); offset < token_length; offset += 1 {
			if values[start + offset] < i64('0') || values[start + offset] > i64('9') do return -1
		}
		zeros := c.size_t(0)
		for zeros < token_length && values[start + zeros] == i64('0') do zeros += 1
		starts[item] = start
		token_lengths[item] = token_length
		normalized_starts[item] = start + zeros
		normalized_lengths[item] = token_length - zeros
		for previous := c.size_t(0); previous < item; previous += 1 {
			if normalized_lengths[previous] != normalized_lengths[item] do continue
			equal := true
			for offset := c.size_t(0); offset < normalized_lengths[item]; offset += 1 {
				if values[normalized_starts[previous] + offset] != values[normalized_starts[item] + offset] {
					equal = false
					break
				}
			}
			if equal {
				if token_lengths[previous] != token_length do return -1
				for offset := c.size_t(0); offset < token_length; offset += 1 {
					if values[starts[previous] + offset] != values[start + offset] do return -1
				}
			}
		}
		output_length += token_length
		cursor += token_length
		order[item] = item
	}
	if cursor != length || output_length > MAX_OUTPUT_LENGTH do return -1

	for item := c.size_t(1); item < count; item += 1 {
		key := order[item]
		position := item
		for position > 0 && token_less(values, normalized_starts[key], normalized_lengths[key],
		                              normalized_starts[order[position - 1]], normalized_lengths[order[position - 1]]) {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = key
	}
	if (output == nil && output_length != 0) || output_capacity < output_length do return -2
	written := c.size_t(0)
	for item := c.size_t(0); item < count; item += 1 {
		if item > 0 { output[written] = u8(' '); written += 1 }
		index := order[item]
		for offset := c.size_t(0); offset < token_lengths[index]; offset += 1 {
			output[written] = u8(values[starts[index] + offset])
			written += 1
		}
	}
	return i64(output_length)
}
