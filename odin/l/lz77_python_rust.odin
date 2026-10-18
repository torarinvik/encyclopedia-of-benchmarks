package lz77_python_rust

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_INPUT_LENGTH :: 66
MAX_OUTPUT_BYTES :: 1536

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (byte * 8)) & 0xff)
	}
}

@(export)
lz77_python_rust_compress :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_TEXT_LENGTH do return -1
	text_length := int(input[0])
	if int(input_length) != 1 + text_length do return -1
	for index := 0; index < text_length; index += 1 {
		if input[index + 1] < 32 || input[index + 1] > 126 do return -1
	}
	if text_length > 0 {
		final_character := input[text_length]
		occurrences := 0
		for index := 0; index < text_length; index += 1 {
			if input[index + 1] == final_character do occurrences += 1
		}
		if occurrences != 1 do return -1
	}

	staged: [MAX_OUTPUT_BYTES]u8
	token_count := 0
	current := 0
	for current < text_length {
		best_offset := 0
		best_length := 0
		search_start := if current > 7 then current - 7 else 0
		for candidate := search_start; candidate < current; candidate += 1 {
			offset := current - candidate
			match_length := 0
			for current + match_length < text_length {
				source := candidate + match_length
				if source >= current do source = candidate + match_length % offset
				if input[source + 1] != input[current + match_length + 1] do break
				match_length += 1
			}
			if match_length >= text_length - current do return -1
			if match_length >= best_length {
				best_offset = offset
				best_length = match_length
			}
		}
		if best_length >= text_length - current do return -1
		indicator := input[current + best_length + 1]
		byte_offset := token_count * 24
		store_i64_le(&staged[0], byte_offset, i64(best_offset))
		store_i64_le(&staged[0], byte_offset + 8, i64(best_length))
		store_i64_le(&staged[0], byte_offset + 16, indicator)
		token_count += 1
		current += best_length + 1
	}

	output_bytes := token_count * 24
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
