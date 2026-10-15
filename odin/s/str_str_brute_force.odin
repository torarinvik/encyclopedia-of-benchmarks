package str_str_brute_force

import "core:c"

MAX_STRING_LENGTH :: 1024

// Return the first pattern occurrence using a direct character-by-character scan.
@(export)
str_str_brute_force :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 2 + 2 * MAX_STRING_LENGTH do return -1
	if packed[0] < 0 || packed[0] > MAX_STRING_LENGTH ||
		packed[1] < 0 || packed[1] > MAX_STRING_LENGTH {
		return -1
	}
	text_length := int(packed[0])
	pattern_length := int(packed[1])
	if int(length) != 2 + text_length + pattern_length do return -1
	for index := 0; index < text_length + pattern_length; index += 1 {
		if packed[2 + index] < 1 || packed[2 + index] > 127 do return -1
	}
	if pattern_length == 0 do return 0
	if pattern_length > text_length do return -1

	pattern_start := 2 + text_length
	for start := 0; start <= text_length - pattern_length; start += 1 {
		offset := 0
		for offset < pattern_length && packed[2 + start + offset] == packed[pattern_start + offset] {
			offset += 1
		}
		if offset == pattern_length do return i64(start)
	}
	return -1
}
