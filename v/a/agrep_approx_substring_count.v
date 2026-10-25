module agrep_approx_substring_count

const max_pattern_length = 63
const max_text_length = 4096
const max_errors = 2

@[export: 'agrep_approx_substring_count']
pub fn agrep_approx_substring_count(values &i64, length usize) i64 {
	if length < 3 { return -2 }
	pattern_value := unsafe { values[0] }
	text_value := unsafe { values[1] }
	error_value := unsafe { values[2] }
	if pattern_value < 1 || pattern_value > max_pattern_length || text_value < 0 ||
			text_value > max_text_length || error_value < 0 || error_value > max_errors { return -2 }
	pattern_length := int(pattern_value)
	text_length := int(text_value)
	if length != usize(3 + pattern_length + text_length) { return -2 }
	for index in 3 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -2 }
	}

	mut previous := [64]i64{}
	mut current := [64]i64{}
	for index in 0 .. pattern_length + 1 { previous[index] = i64(index) }
	mut matches := i64(0)
	text_offset := 3 + pattern_length
	for text_index in 0 .. text_length {
		current[0] = 0
		for pattern_index in 1 .. pattern_length + 1 {
			substitution := previous[pattern_index - 1] + 1
			if unsafe { values[3 + pattern_index - 1] } == unsafe { values[text_offset + text_index] } {
				substitution -= 1
			}
			mut best := previous[pattern_index] + 1
			if current[pattern_index - 1] + 1 < best { best = current[pattern_index - 1] + 1 }
			if substitution < best { best = substitution }
			current[pattern_index] = best
		}
		if current[pattern_length] <= error_value { matches += 1 }
		for index in 0 .. pattern_length + 1 { previous[index] = current[index] }
	}
	return matches
}
