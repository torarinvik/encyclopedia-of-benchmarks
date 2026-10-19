package mibench_office_stringsearch_bmh

import "core:c"

// Modified derivative of MiBench bmhsrch.c; public domain by Raymond Gardner (7/92).
MAX_TEXT :: 128
MAX_PATTERN :: 32
MAX_INPUT :: 162

@(export)
mibench_office_stringsearch_bmh :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	text_length_value := input[0]
	pattern_length_value := input[1]
	if text_length_value < 0 || text_length_value > MAX_TEXT ||
		pattern_length_value < 1 || pattern_length_value > MAX_PATTERN do return -1
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if int(length) != 2 + text_length + pattern_length do return -1
	text: [MAX_TEXT]u8 = {}
	pattern: [MAX_PATTERN]u8 = {}
	for i in 0 ..< text_length + pattern_length {
		value := input[2 + i]
		if value < 32 || value > 126 do return -1
		if i < text_length do text[i] = u8(value)
		else do pattern[i - text_length] = u8(value)
	}
	shift: [256]int = {}
	for i in 0 ..< 256 do shift[i] = pattern_length
	for i in 0 ..< pattern_length - 1 do shift[int(pattern[i])] = pattern_length - i - 1
	match: i64 = -1
	if pattern_length <= text_length {
		start := 0
		for start <= text_length - pattern_length {
			j := pattern_length
			for j > 0 && text[start + j - 1] == pattern[j - 1] do j -= 1
			if j == 0 { match = i64(start); break }
			start += shift[int(text[start + pattern_length - 1])]
		}
	}
	if output == nil || output_capacity < 8 do return -2
	bits := transmute(u64)match
	for i in 0 ..< 8 do output[i] = u8((bits >> (8 * i)) & 255)
	return 8
}
