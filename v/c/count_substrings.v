module count_substrings

const max_length = 4096

fn find_next(values &i64, text_length int, pattern_length int, pattern_start int, start int) i64 {
	if start > text_length || pattern_length > text_length - start { return -1 }
	last := text_length - pattern_length
	for position := start; position <= last; position++ {
		offset := 0
		for offset < pattern_length {
			text_value := unsafe { values[2 + position + offset] }
			pattern_value := unsafe { values[pattern_start + offset] }
			if text_value != pattern_value { break }
			offset++
		}
		if offset == pattern_length { return i64(position) }
	}
	return -1
}

@[export: 'count_substrings']
pub fn count_substrings(values &i64, length usize) i64 {
	if length < 2 { return -1 }
	text_value := unsafe { values[0] }
	pattern_value := unsafe { values[1] }
	if text_value < 0 || text_value > max_length || pattern_value < 0 || pattern_value > max_length { return -1 }
	text_length := int(text_value)
	pattern_length := int(pattern_value)
	if length != usize(2 + text_length + pattern_length) { return -1 }
	for i in 2 .. int(length) {
		value := unsafe { values[i] }
		if value < 0 || value > 127 { return -1 }
	}
	if pattern_length == 0 { return i64(text_length + 1) }
	pattern_start := 2 + text_length
	mut count := i64(0)
	mut start := 0
	for {
		position := find_next(values, text_length, pattern_length, pattern_start, start)
		if position < 0 { break }
		count++
		start = int(position) + 1
	}
	return count
}
