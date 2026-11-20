package alpha_skip_search

import "core:c"

MAX_TEXT_LENGTH :: 4096
MAX_PATTERN_LENGTH :: 128
MAX_BUCKETS :: 64
MAX_INPUT_LENGTH :: 4227

@(export)
alpha_skip_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	text_length64, pattern_length64 := input[0], input[1]
	if text_length64 < 0 || text_length64 > MAX_TEXT_LENGTH || pattern_length64 < 1 || pattern_length64 > MAX_PATTERN_LENGTH do return -1
	text_length, pattern_length := int(text_length64), int(pattern_length64)
	if length != c.size_t(2+text_length+pattern_length) do return -1
	var text: [MAX_TEXT_LENGTH]u8
	var pattern: [MAX_PATTERN_LENGTH]u8
	for i := 0; i < text_length; i += 1 {
		symbol := input[2+i]
		if symbol < 0 || symbol > 3 do return -1
		text[i] = u8(symbol)
	}
	pattern_offset := 2 + text_length
	for i := 0; i < pattern_length; i += 1 {
		symbol := input[pattern_offset+i]
		if symbol < 0 || symbol > 3 do return -1
		pattern[i] = u8(symbol)
	}

	factor_length := 1
	bucket_count := 4
	for bucket_count*4 <= pattern_length {
		bucket_count *= 4
		factor_length += 1
	}
	factor_count := pattern_length - factor_length + 1
	factor_power := 1
	for i := 1; i < factor_length; i += 1 do factor_power *= 4
	var heads: [MAX_BUCKETS]int
	for i := 0; i < MAX_BUCKETS; i += 1 do heads[i] = -1
	var next_position: [MAX_PATTERN_LENGTH]int
	code := 0
	for i := 0; i < factor_length; i += 1 do code = code*4 + int(pattern[i])
	for position := 0; position < factor_count; position += 1 {
		if position > 0 do code = (code-int(pattern[position-1])*factor_power)*4 + int(pattern[position+factor_length-1])
		next_position[position] = heads[code]
		heads[code] = position
	}
	if text_length < pattern_length do return 0
	shift := pattern_length - factor_length + 1
	var match_count: i64 = 0
	var offset_sum: i64 = 0
	var offset_xor: i64 = 0
	for sample_start := 0; sample_start <= text_length-factor_length; sample_start += shift {
		text_code := 0
		for offset := 0; offset < factor_length; offset += 1 do text_code = text_code*4 + int(text[sample_start+offset])
		pattern_position := heads[text_code]
		for pattern_position >= 0 {
			candidate := sample_start - pattern_position
			if candidate >= 0 && candidate <= text_length-pattern_length {
				matches := true
				for offset := 0; offset < pattern_length; offset += 1 {
					if text[candidate+offset] != pattern[offset] { matches = false; break }
				}
				if matches {
					match_count += 1
					offset_sum += i64(candidate)
					offset_xor ^= i64(candidate)
				}
			}
			pattern_position = next_position[pattern_position]
		}
	}
	return (match_count << 36) | (offset_sum << 12) | offset_xor
}
