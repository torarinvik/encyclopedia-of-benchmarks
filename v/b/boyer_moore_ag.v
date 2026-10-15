module boyer_moore_ag

fn collect_matches(values &i64, text_length usize, pattern_length usize,
	pattern_start usize, positions &mut u8) usize {
	mut bad_shift := [128]usize{}
	mut present := [128]bool{}
	mut suffix_skip := [256]usize{}
	for index := usize(0); index + 1 < pattern_length; index++ {
		byte := usize(unsafe { values[pattern_start + index] })
		bad_shift[byte] = pattern_length - index - 1
		present[byte] = true
	}
	for byte := usize(0); byte < 128; byte++ {
		if !present[byte] { continue }
		shift := bad_shift[byte]
		mut matched := usize(0)
		for matched < pattern_length - shift && unsafe { values[pattern_start + pattern_length - 1 - matched] == values[pattern_start + pattern_length - 1 - shift - matched] } { matched++ }
		suffix_skip[shift] = matched
	}

	mut count := usize(0)
	mut start := usize(0)
	mut jump := pattern_length
	for start <= text_length - pattern_length {
		skip := suffix_skip[jump]
		mut index := int(pattern_length) - 1
		for index >= 0 {
			if unsafe { values[2 + start + usize(index)] != values[pattern_start + usize(index)] } {
				mismatch := usize(unsafe { values[2 + start + usize(index)] })
				jump = if present[mismatch] { bad_shift[mismatch] } else { pattern_length }
				start += jump
				break
			}
			if usize(index) == pattern_length - jump { index -= int(skip) }
			if index == 0 {
				unsafe { positions[count] = u8(start) }
				count++
				jump = 1
				start++
				break
			}
			index--
		}
	}
	return count
}

@[export: 'boyer_moore_ag']
pub fn boyer_moore_ag(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length < 2 || length > 512 { return -1 }
	if unsafe { values[0] } < 0 || unsafe { values[0] } > 255 || unsafe { values[1] } < 1 || unsafe { values[1] } > 255 { return -1 }
	text_length := usize(unsafe { values[0] })
	pattern_length := usize(unsafe { values[1] })
	if length != 2 + text_length + pattern_length { return -1 }
	for index := usize(0); index < text_length + pattern_length; index++ {
		byte := unsafe { values[2 + index] }
		if byte < 0 || byte > 127 { return -1 }
	}
	mut positions := [255]u8{}
	mut count := usize(0)
	if pattern_length <= text_length { count = collect_matches(values, text_length, pattern_length, 2 + text_length, &positions[0]) }
	if output_capacity < count { return -2 }
	for index := usize(0); index < count; index++ { unsafe { output[index] = positions[index] } }
	return i64(count)
}
