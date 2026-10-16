module text_justification

const max_width = 64
const max_text_bytes = 512
const max_words = 64
const max_input_length = 2 + max_text_bytes + 1
const max_output_bytes = max_words * max_width + max_words

@[export: 'text_justification']
pub fn text_justification(input &i64, length usize, output &u8, capacity usize) i64 {
	if isnil(input) || length < 2 || length > usize(max_input_length) { return -1 }
	width_value := unsafe { input }
	text_length_value := unsafe { input[1] }
	if width_value < 1 || width_value > max_width || text_length_value < 0 || text_length_value > max_text_bytes { return -1 }
	width := int(width_value)
	text_length := int(text_length_value)
	if length != usize(2 + text_length) { return -1 }
	mut text := []u8{len: max_text_bytes}
	for i in 0 .. text_length {
		value := unsafe { input[i + 2] }
		if value != 32 && (value < 33 || value > 126) { return -1 }
		text[i] = u8(value)
	}
	mut starts := []int{len: max_words}
	mut lengths := []int{len: max_words}
	mut word_count := 0
	mut pos := 0
	for pos < text_length {
		for pos < text_length && text[pos] == ` ` { pos++ }
		if pos == text_length { break }
		start := pos
		for pos < text_length && text[pos] != ` ` { pos++ }
		word_length := pos - start
		if word_count == max_words || word_length > width { return -1 }
		starts[word_count] = start
		lengths[word_count] = word_length
		word_count++
	}
	mut result := []u8{len: max_output_bytes}
	mut result_length := 0
	mut line_start := 0
	mut line_end := 0
	mut letters := 0
	mut first_line := true
	for word in 0 .. word_count {
		if letters + lengths[word] + (line_end - line_start) <= width {
			letters += lengths[word]
			line_end++
			continue
		}
		if !first_line { result[result_length] = `\n`; result_length++ }
		first_line = false
		count := line_end - line_start
		if count == 1 {
			for i in 0 .. lengths[line_start] { result[result_length] = text[starts[line_start] + i]; result_length++ }
			for _ in lengths[line_start] .. width { result[result_length] = ` `; result_length++ }
		} else {
			gaps := count - 1
			spaces := width - letters
			base := spaces / gaps
			extra := spaces % gaps
			for item in 0 .. count {
				current := line_start + item
				for i in 0 .. lengths[current] { result[result_length] = text[starts[current] + i]; result_length++ }
				if item + 1 < count {
					mut gap_spaces := base
					if item < extra { gap_spaces++ }
					for _ in 0 .. gap_spaces { result[result_length] = ` `; result_length++ }
				}
			}
		}
		line_start = word
		line_end = word + 1
		letters = lengths[word]
	}
	if !first_line { result[result_length] = `\n`; result_length++ }
	for item in line_start .. line_end {
		if item != line_start { result[result_length] = ` `; result_length++ }
		for i in 0 .. lengths[item] { result[result_length] = text[starts[item] + i]; result_length++ }
	}
	trailing := width - letters - (line_end - line_start) + 1
	for _ in 0 .. trailing { result[result_length] = ` `; result_length++ }
	if capacity < usize(result_length) || (result_length != 0 && isnil(output)) { return -2 }
	for i in 0 .. result_length { unsafe { output[i] = result[i] } }
	return i64(result_length)
}
