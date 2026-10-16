module strip

fn strip_contains(value i64, input &i64, set_start usize, set_length i64) bool {
	if set_length == -1 {
		return value == 9 || value == 10 || value == 13 || value == 32
	}
	for index in 0 .. int(set_length) {
		if unsafe { input[set_start + usize(index)] } == value { return true }
	}
	return false
}

@[export: 'strip']
pub fn strip(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 386 { return -1 }
		if input[0] < 0 || input[0] > 256 { return -1 }
		text_length := usize(input[0])
		set_index := 1 + text_length
		if set_index >= length { return -1 }
		set_length := input[set_index]
		expected_length := usize(0)
		if set_length == -1 {
			expected_length = set_index + 1
		} else {
			if set_length < 0 || set_length > 128 { return -1 }
			expected_length = set_index + 1 + usize(set_length)
		}
		if length != expected_length { return -1 }
		for index in 0 .. int(text_length) {
			if input[1 + index] < 0 || input[1 + index] > 127 { return -1 }
		}
		if set_length >= 0 {
			for index in 0 .. int(set_length) {
				if input[set_index + 1 + index] < 0 || input[set_index + 1 + index] > 127 { return -1 }
			}
		}

		mut start := usize(0)
		mut ending := text_length
		for start < ending && strip_contains(input[1 + start], input, set_index + 1, set_length) {
			start++
		}
		for ending > start && strip_contains(input[ending], input, set_index + 1, set_length) {
			ending--
		}
		output_length := ending - start
		if output_capacity < output_length || (output_length > 0 && output == nil) { return -2 }
		for index in 0 .. int(output_length) {
			output[index] = u8(input[1 + start + usize(index)])
		}
		return i64(output_length)
	}
}
