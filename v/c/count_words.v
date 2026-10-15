module count_words

const max_length = 4096

fn is_trim_character(value i64) bool { return value <= 32 }
fn is_regex_whitespace(value i64) bool { return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32 }

// Count tokens after Java String.trim() and split("\\s+").
@[export: 'count_words']
pub fn count_words(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	if length == 0 { return 0 }
	unsafe {
		data := values[..length]
		for value in data {
			if value < 0 || value > 127 { return -1 }
		}
		mut start := 0
		mut ending := int(length)
		for start < ending && is_trim_character(data[start]) { start++ }
		for ending > start && is_trim_character(data[ending - 1]) { ending-- }
		if start == ending { return 1 }
		mut count := i64(0)
		mut in_word := false
		for i := start; i < ending; i++ {
			if is_regex_whitespace(data[i]) {
				in_word = false
			} else if !in_word {
				count++
				in_word = true
			}
		}
		return count
	}
}
