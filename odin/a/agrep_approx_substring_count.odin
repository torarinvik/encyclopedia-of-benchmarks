package agrep_approx_substring_count

import "core:c"

MAX_PATTERN_LENGTH :: 63
MAX_TEXT_LENGTH :: 4096
MAX_ERRORS :: 2

@(export)
agrep_approx_substring_count :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || values[0] < 1 || values[0] > MAX_PATTERN_LENGTH ||
			values[1] < 0 || values[1] > MAX_TEXT_LENGTH || values[2] < 0 || values[2] > MAX_ERRORS {
		return -2
	}
	pattern_length := int(values[0])
	text_length := int(values[1])
	if int(length) != 3 + pattern_length + text_length { return -2 }
	for index := 3; index < int(length); index += 1 {
		if values[index] < 32 || values[index] > 126 { return -2 }
	}

	previous: [64]i64
	current: [64]i64
	for index := 0; index <= pattern_length; index += 1 { previous[index] = i64(index) }
	matches := i64(0)
	text_offset := 3 + pattern_length
	for text_index := 0; text_index < text_length; text_index += 1 {
		current[0] = 0
		for pattern_index := 1; pattern_index <= pattern_length; pattern_index += 1 {
			substitution := previous[pattern_index-1] + 1
			if values[3+pattern_index-1] == values[text_offset+text_index] { substitution -= 1 }
			best := previous[pattern_index] + 1
			if current[pattern_index-1]+1 < best { best = current[pattern_index-1] + 1 }
			if substitution < best { best = substitution }
			current[pattern_index] = best
		}
		if current[pattern_length] <= values[2] { matches += 1 }
		for index := 0; index <= pattern_length; index += 1 { previous[index] = current[index] }
	}
	return matches
}
