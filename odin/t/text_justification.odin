package text_justification

import "core:c"

MAX_WIDTH :: 64
MAX_TEXT_BYTES :: 512
MAX_WORDS :: 64
MAX_INPUT_LENGTH :: 2 + MAX_TEXT_BYTES + 1
MAX_OUTPUT_BYTES :: MAX_WORDS * MAX_WIDTH + MAX_WORDS

@(export)
text_justification :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	width_value := input[0]
	text_length_value := input[1]
	if width_value < 1 || width_value > MAX_WIDTH || text_length_value < 0 || text_length_value > MAX_TEXT_BYTES do return -1
	width := int(width_value)
	text_length := int(text_length_value)
	if int(length) != 2 + text_length do return -1
	text: [MAX_TEXT_BYTES]u8
	for i in 0..<text_length {
		value := input[i+2]
		if value != 32 && (value < 33 || value > 126) do return -1
		text[i] = u8(value)
	}
	starts: [MAX_WORDS]int
	lengths: [MAX_WORDS]int
	word_count := 0
	pos := 0
	for pos < text_length {
		for pos < text_length && text[pos] == ' ' { pos += 1 }
		if pos == text_length do break
		start := pos
		for pos < text_length && text[pos] != ' ' { pos += 1 }
		word_length := pos - start
		if word_count == MAX_WORDS || word_length > width do return -1
		starts[word_count] = start
		lengths[word_count] = word_length
		word_count += 1
	}
	result: [MAX_OUTPUT_BYTES]u8
	result_length := 0
	line_start, line_end, letters := 0, 0, 0
	first_line := true
	for word in 0..<word_count {
		if letters + lengths[word] + (line_end-line_start) <= width {
			letters += lengths[word]
			line_end += 1
			continue
		}
		if !first_line { result[result_length] = '\n'; result_length += 1 }
		first_line = false
		count := line_end - line_start
		if count == 1 {
			for i in 0..<lengths[line_start] { result[result_length] = text[starts[line_start]+i]; result_length += 1 }
			for _ in lengths[line_start]..<width { result[result_length] = ' '; result_length += 1 }
		} else {
			gaps := count - 1
			spaces := width - letters
			base := spaces / gaps
			extra := spaces % gaps
			for item in 0..<count {
				current := line_start + item
				for i in 0..<lengths[current] { result[result_length] = text[starts[current]+i]; result_length += 1 }
				if item + 1 < count {
					gap_spaces := base
					if item < extra { gap_spaces += 1 }
					for _ in 0..<gap_spaces { result[result_length] = ' '; result_length += 1 }
				}
			}
		}
		line_start = word
		line_end = word + 1
		letters = lengths[word]
	}
	if !first_line { result[result_length] = '\n'; result_length += 1 }
	for item in line_start..<line_end {
		if item != line_start { result[result_length] = ' '; result_length += 1 }
		for i in 0..<lengths[item] { result[result_length] = text[starts[item]+i]; result_length += 1 }
	}
	trailing := width - letters - (line_end-line_start) + 1
	for _ in 0..<trailing { result[result_length] = ' '; result_length += 1 }
	if capacity < c.size_t(result_length) || (result_length != 0 && output == nil) do return -2
	for i in 0..<result_length { output[i] = result[i] }
	return i64(result_length)
}
