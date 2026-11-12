module crochemore_perrin_two_way

const max_text_length = 64
const max_pattern_length = 32
const max_input_length = 99

fn maximal_suffix(pattern []i64, reverse_order bool) (int, int) {
	mut maximal := -1
	mut candidate := 0
	mut offset := 1
	mut period := 1
	for candidate + offset < pattern.len {
		a := pattern[candidate + offset]
		b := pattern[maximal + offset]
		precedes := if reverse_order { a > b } else { a < b }
		if precedes {
			candidate += offset
			offset = 1
			period = candidate - maximal
		} else if a == b {
			if offset != period { offset++ } else { candidate += period; offset = 1 }
		} else {
			maximal = candidate
			candidate = maximal + 1
			offset = 1
			period = 1
		}
	}
	return maximal, period
}

fn two_way(text []i64, pattern []i64) []i64 {
	n := text.len
	m := pattern.len
	mut matches := []i64{}
	if m == 0 {
		for i in 0 .. n + 1 { matches << i64(i) }
		return matches
	}
	if m > n { return matches }
	first_critical, first_period := maximal_suffix(pattern, false)
	second_critical, second_period := maximal_suffix(pattern, true)
	critical := if first_critical > second_critical { first_critical } else { second_critical }
	period := if first_critical > second_critical { first_period } else { second_period }
	mut periodic := period + critical + 1 <= m
	if periodic {
		for i := 0; i <= critical; i++ {
			if pattern[i] != pattern[i + period] { periodic = false; break }
		}
	}
	shift := if periodic { period } else { max(critical, m - critical - 1) + 1 }
	mut memory := -1
	mut start := 0
	for start <= n - m {
		mut index := if periodic { max(critical, memory) + 1 } else { critical + 1 }
		for index < m && pattern[index] == text[start + index] { index++ }
		if index >= m {
			index = critical
			for index > memory && pattern[index] == text[start + index] { index-- }
			if index <= memory { matches << i64(start) }
			start += shift
			memory = if periodic { m - period - 1 } else { -1 }
		} else {
			start += index - critical
			memory = -1
		}
	}
	return matches
}

@[export: 'crochemore_perrin_two_way']
pub fn crochemore_perrin_two_way(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > max_input_length { return -1 }
		if values[0] < 0 || values[0] > max_text_length || values[1] < 0 || values[1] > max_pattern_length { return -1 }
		text_length := int(values[0])
		pattern_length := int(values[1])
		if length != usize(2 + text_length + pattern_length) { return -1 }
		mut text := []i64{len: text_length, init: 0}
		mut pattern := []i64{len: pattern_length, init: 0}
		for i in 0 .. text_length {
			value := values[2 + i]
			if value < 0 || value > 255 { return -1 }
			text[i] = value
		}
		for i in 0 .. pattern_length {
			value := values[2 + text_length + i]
			if value < 0 || value > 255 { return -1 }
			pattern[i] = value
		}
		matches := two_way(text, pattern)
		output_bytes := matches.len * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for i, position in matches {
			bits := u64(position)
			for byte in 0 .. 8 { output[i * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
		}
		return i64(output_bytes)
	}
}
