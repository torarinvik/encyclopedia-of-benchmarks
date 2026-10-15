module naive_search

@[export: 'naive_search']
pub fn naive_search(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length < 2 || length > 512 { return -1 }
	if unsafe { values[0] } < 0 || unsafe { values[0] } > 255 || unsafe { values[1] } < 0 || unsafe { values[1] } > 255 { return -1 }
	text_length := usize(unsafe { values[0] })
	pattern_length := usize(unsafe { values[1] })
	if length != 2 + text_length + pattern_length { return -1 }
	pattern_start := 2 + text_length
	for index := usize(0); index < text_length; index++ {
		byte := unsafe { values[2 + index] }
		if byte < 1 || byte > 127 { return -1 }
	}
	for index := usize(0); index < pattern_length; index++ {
		byte := unsafe { values[pattern_start + index] }
		if byte < 1 || byte > 127 { return -1 }
	}

	mut match_count := usize(0)
	if pattern_length <= text_length {
		for start := usize(0); start <= text_length - pattern_length; start++ {
			mut offset := usize(0)
			for offset < pattern_length && unsafe { values[2 + start + offset] == values[pattern_start + offset] } { offset++ }
			if offset == pattern_length { match_count++ }
		}
	}
	if output_capacity < match_count { return -2 }
	mut written := usize(0)
	if pattern_length <= text_length {
		for start := usize(0); start <= text_length - pattern_length; start++ {
			mut offset := usize(0)
			for offset < pattern_length && unsafe { values[2 + start + offset] == values[pattern_start + offset] } { offset++ }
			if offset == pattern_length {
				unsafe { output[written] = u8(start) }
				written++
			}
		}
	}
	return i64(written)
}
