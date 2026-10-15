module boyer_moore_horspool

fn count_matches(values &i64, text_length usize, pattern_length usize,
	pattern_start usize, shifts [128]usize) usize {
	if pattern_length == 0 { return text_length + 1 }
	if pattern_length > text_length { return 0 }
	mut count := usize(0)
	mut start := usize(0)
	for start <= text_length - pattern_length {
		mut current := pattern_length
		for current > 0 && unsafe { values[pattern_start + current - 1] == values[2 + start + current - 1] } { current-- }
		if current == 0 {
			count++
			start++
		} else {
			tail := usize(unsafe { values[2 + start + pattern_length - 1] })
			start += shifts[tail]
		}
	}
	return count
}

@[export: 'boyer_moore_horspool']
pub fn boyer_moore_horspool(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length < 2 || length > 512 { return -1 }
	if unsafe { values[0] } < 0 || unsafe { values[0] } > 255 || unsafe { values[1] } < 0 || unsafe { values[1] } > 255 { return -1 }
	text_length := usize(unsafe { values[0] })
	pattern_length := usize(unsafe { values[1] })
	if length != 2 + text_length + pattern_length { return -1 }
	pattern_start := 2 + text_length
	for index := usize(0); index < text_length + pattern_length; index++ {
		byte := unsafe { values[2 + index] }
		if byte < 0 || byte > 127 { return -1 }
	}

	mut shifts := [128]usize{}
	for byte := usize(0); byte < 128; byte++ { shifts[byte] = pattern_length }
	for index := usize(0); index + 1 < pattern_length; index++ {
		shifts[usize(unsafe { values[pattern_start + index] })] = pattern_length - 1 - index
	}
	match_count := count_matches(values, text_length, pattern_length, pattern_start, shifts)
	if output_capacity < match_count { return -2 }

	mut written := usize(0)
	if pattern_length == 0 {
		for position := usize(0); position <= text_length; position++ {
			unsafe { output[written] = u8(position) }
			written++
		}
	} else if pattern_length <= text_length {
		mut start := usize(0)
		for start <= text_length - pattern_length {
			mut current := pattern_length
			for current > 0 && unsafe { values[pattern_start + current - 1] == values[2 + start + current - 1] } { current-- }
			if current == 0 {
				unsafe { output[written] = u8(start) }
				written++
				start++
			} else {
				tail := usize(unsafe { values[2 + start + pattern_length - 1] })
				start += shifts[tail]
			}
		}
	}
	return i64(written)
}
