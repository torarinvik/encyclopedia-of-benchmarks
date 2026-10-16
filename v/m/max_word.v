module max_word

const max_text_length = 512
const max_input_length = max_text_length + 2

fn lower_ascii(value u8) u8 {
	if value >= `A` && value <= `Z` { return value + (`a` - `A`) }
	return value
}

@[export: 'max_word']
pub fn max_word(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if isnil(input) || length < 1 || length > usize(max_input_length) { return -1 }
	text_length_value := unsafe { input }
	if text_length_value < 1 || text_length_value > max_text_length { return -1 }
	text_length := int(text_length_value)
	if length != usize(1 + text_length) { return -1 }

	mut text := []u8{len: max_text_length}
	for i in 0 .. text_length {
		value := unsafe { input[i + 1] }
		is_letter := (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
		if value == 32 {
			if i == 0 || i + 1 == text_length || text[i - 1] == ` ` { return -1 }
		} else if !is_letter || value == 73 {
			return -1
		}
		text[i] = u8(value)
	}

	mut starts := []int{len: max_text_length}
	mut lengths := []int{len: max_text_length}
	mut counts := []int{len: max_text_length}
	mut unique_count := 0
	mut start := 0
	for start < text_length {
		mut end := start
		for end < text_length && text[end] != ` ` { end++ }
		word_length := end - start
		if word_length > 6 { return -1 }
		mut found := unique_count
		for key in 0 .. unique_count {
			if lengths[key] != word_length { continue }
			mut offset := 0
			for offset < word_length && lower_ascii(text[starts[key] + offset]) == lower_ascii(text[start + offset]) { offset++ }
			if offset == word_length { found = key; break }
		}
		if found == unique_count {
			starts[unique_count] = start
			lengths[unique_count] = word_length
			counts[unique_count] = 1
			unique_count++
		} else {
			counts[found]++
		}
		start = end + 1
	}

	mut winner := 0
	for key in 1 .. unique_count { if counts[key] > counts[winner] { winner = key } }
	result_length := lengths[winner]
	if output_capacity < usize(result_length) || isnil(output) { return -2 }
	single_word := unique_count == 1 && counts[0] == 1
	for i in 0 .. result_length {
		value := text[starts[winner] + i]
		unsafe { output[i] = if single_word { value } else { lower_ascii(value) } }
	}
	return i64(result_length)
}
