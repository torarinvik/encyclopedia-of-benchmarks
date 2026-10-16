package bitap_string_match

import "core:c"

MAX_TEXT_LENGTH :: 4096
MAX_PATTERN_LENGTH :: 63

@(export)
bitap_string_match :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || values[0] < 0 || values[0] > MAX_TEXT_LENGTH ||
			values[1] < 0 || values[1] > MAX_PATTERN_LENGTH {
		return -2
	}
	text_length := int(values[0])
	pattern_length := int(values[1])
	if int(length) != 2 + text_length + pattern_length {
		return -2
	}
	for index := 2; index < int(length); index += 1 {
		if values[index] < 97 || values[index] > 122 {
			return -2
		}
	}
	if pattern_length == 0 {
		return 0
	}
	if pattern_length > text_length {
		return -1
	}

	masks: [26]u64
	for letter := 0; letter < 26; letter += 1 {
		masks[letter] = ~u64(0)
	}
	for index := 0; index < pattern_length; index += 1 {
		letter := int(values[2+text_length+index] - 97)
		masks[letter] &= ~(u64(1) << u64(index))
	}
	state := ~u64(1)
	for index := 0; index < text_length; index += 1 {
		letter := int(values[2+index] - 97)
		state |= masks[letter]
		state <<= 1
		if state&(u64(1)<<u64(pattern_length)) == 0 {
			return i64(index - pattern_length + 1)
		}
	}
	return -1
}
