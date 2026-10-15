package horspool_search

import "core:c"

@(export)
horspool_search :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length < 2 do return -2
	text_length_value := packed[0]
	pattern_length_value := packed[1]
	if text_length_value < 0 || text_length_value > 512 || pattern_length_value < 0 || pattern_length_value > 64 do return -2
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if length != c.size_t(text_length + pattern_length + 2) do return -2
	pattern_start := 2 + text_length
	for index := 0; index < text_length; index += 1 {
		if packed[index + 2] < 0 || packed[index + 2] > 127 do return -2
	}
	for index := 0; index < pattern_length; index += 1 {
		if packed[pattern_start + index] < 0 || packed[pattern_start + index] > 127 do return -2
	}
	if pattern_length == 0 || pattern_length > text_length do return -1
	shifts: [128]int = {}
	for ch := 0; ch < 128; ch += 1 { shifts[ch] = pattern_length }
	for index := pattern_length - 2; index >= 0; index -= 1 {
		ch := int(packed[pattern_start + index])
		if shifts[ch] == pattern_length do shifts[ch] = pattern_length - 1 - index
	}
	end_index := pattern_length - 1
	for end_index < text_length {
		offset := 0
		for offset < pattern_length && packed[pattern_start + pattern_length - 1 - offset] == packed[2 + end_index - offset] { offset += 1 }
		if offset == pattern_length do return i64(end_index - pattern_length + 1)
		end_index += shifts[int(packed[2 + end_index])]
	}
	return -1
}
