module count_sentences

const max_text_length = 4096

fn is_trim_byte(value u8) bool {
	return value == 0 || value == 9 || value == 10 || value == 11 || value == 13 || value == 32
}
fn is_regex_space(value u8) bool {
	return (value >= 9 && value <= 13) || value == 32
}
fn is_word_byte(value u8) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) ||
		(value >= 48 && value <= 57) || value == 95
}
fn is_terminator(value u8) bool {
	return value == 46 || value == 33 || value == 63
}
fn is_eligible_predecessor(value u8) bool {
	return !is_regex_space(value) && value != 124 && value != 94 && value != 46
}

@[export: 'count_sentences']
pub fn count_sentences(input &i64, length usize) i64 {
	if isnil(input) || length < 1 || length > usize(max_text_length + 1) { return -1 }
	text_length_value := unsafe { input[0] }
	if text_length_value < 0 || text_length_value > i64(max_text_length) || length != usize(text_length_value + 1) { return -1 }
	text_length := int(text_length_value)
	mut text := [max_text_length]u8{init: 0}
	for index in 0 .. text_length {
		value := unsafe { input[index + 1] }
		if value < 0 || value > 127 { return -1 }
		text[index] = u8(value)
	}

	mut begin := 0
	mut end := text_length
	for begin < end && is_trim_byte(text[begin]) { begin++ }
	for end > begin && is_trim_byte(text[end - 1]) { end-- }
	mut cursor := begin
	mut count := i64(0)
	for cursor + 1 < end {
		mut found := false
		for index := cursor; index + 1 < end; index++ {
			if is_eligible_predecessor(text[index]) && is_terminator(text[index + 1]) &&
				(index + 2 == end || !is_word_byte(text[index + 2])) {
				count++
				cursor = index + 2
				found = true
				break
			}
		}
		if !found { break }
	}
	return count
}
