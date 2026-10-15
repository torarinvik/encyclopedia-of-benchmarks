package boyer_moore

import "core:c"

// Return the first ASCII byte match using bad-character and good-suffix shifts.
@(export)
boyer_moore :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 8194 do return -1
	if values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 4096 do return -1
	text_length := int(values[0])
	pattern_length := int(values[1])
	if length != c.size_t(2 + text_length + pattern_length) do return -1
	for index := 0; index < text_length + pattern_length; index += 1 {
		if values[2 + index] < 0 || values[2 + index] > 126 do return -1
	}
	if pattern_length == 0 do return 0
	if pattern_length > text_length do return -1

	pattern_start := 2 + text_length
	last_occurrence: [127]i64
	for byte := 0; byte < 127; byte += 1 { last_occurrence[byte] = -1 }
	for index := 0; index < pattern_length; index += 1 {
		last_occurrence[int(values[pattern_start + index])] = i64(index)
	}

	good_suffix: [4097]int
	border_position: [4097]int
	for index := 0; index <= pattern_length; index += 1 {
		good_suffix[index] = 0
		border_position[index] = 0
	}
	i := pattern_length
	j := pattern_length + 1
	border_position[pattern_length] = pattern_length + 1
	for i > 0 {
		for j <= pattern_length && values[pattern_start + i - 1] != values[pattern_start + j - 1] {
			if good_suffix[j] == 0 do good_suffix[j] = j - i
			j = border_position[j]
		}
		i -= 1
		j -= 1
		border_position[i] = j
	}
	j = border_position[0]
	for i = 0; i <= pattern_length; i += 1 {
		if good_suffix[i] == 0 do good_suffix[i] = j
		if i == j do j = border_position[j]
	}

	alignment := 0
	for alignment <= text_length - pattern_length {
		pattern_index := pattern_length
		for pattern_index > 0 && values[pattern_start + pattern_index - 1] == values[2 + alignment + pattern_index - 1] {
			pattern_index -= 1
		}
		if pattern_index == 0 do return i64(alignment)
		text_byte := int(values[2 + alignment + pattern_index - 1])
		bad_shift := pattern_index - 1 - int(last_occurrence[text_byte])
		if bad_shift < 1 do bad_shift = 1
		shift := good_suffix[pattern_index]
		if shift < bad_shift do shift = bad_shift
		alignment += shift
	}
	return -1
}
