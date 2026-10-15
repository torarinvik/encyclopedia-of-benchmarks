module z_algorithm_search

@[export: 'z_algorithm_search']
pub fn z_algorithm_search(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	if unsafe { values[0] } < 0 || unsafe { values[0] } > 2047 || unsafe { values[1] } < 0 || unsafe { values[1] } > 2047 { return -1 }
	text_length := int(unsafe { values[0] })
	pattern_length := int(unsafe { values[1] })
	if length != usize(2 + text_length + pattern_length) { return -1 }
	for i := usize(2); i < length; i++ {
		value := unsafe { values[i] }
		if value < 0 || value > 127 { return -1 }
	}
	if pattern_length == 0 {
		count := text_length + 1
		if output_capacity < usize(4 * count) { return -2 }
		for i := 0; i < count; i++ {
			p := u32(i + 1)
			unsafe { for b := 0; b < 4; b++ { output[4 * i + b] = u8((p >> (8 * b)) & 0xff) } }
		}
		return i64(count)
	}
	mut sequence := [4095]u32{}
	mut z := [4095]int{}
	total := pattern_length + 1 + text_length
	for i := 0; i < pattern_length; i++ {
		mut value := u32(unsafe { values[2 + text_length + i] })
		if value >= u32(`A`) && value <= u32(`Z`) { value += 32 }
		sequence[i] = value
	}
	sequence[pattern_length] = 256
	for i := 0; i < text_length; i++ {
		mut value := u32(unsafe { values[2 + i] })
		if value >= u32(`A`) && value <= u32(`Z`) { value += 32 }
		sequence[pattern_length + 1 + i] = value
	}
	mut left := 0
	mut right := 0
	for i := 1; i < total; i++ {
		if i < right { z[i] = if z[i - left] < right - i { z[i - left] } else { right - i } }
		for i + z[i] < total && sequence[z[i]] == sequence[i + z[i]] { z[i]++ }
		if i + z[i] > right { left = i; right = i + z[i] }
	}
	mut count := 0
	for i := pattern_length + 1; i < total; i++ { if z[i] >= pattern_length { count++ } }
	if output_capacity < usize(4 * count) { return -2 }
	mut write := 0
	for i := pattern_length + 1; i < total; i++ {
		if z[i] >= pattern_length {
			p := u32(i - pattern_length)
			unsafe { for b := 0; b < 4; b++ { output[4 * write + b] = u8((p >> (8 * b)) & 0xff) } }
			write++
		}
	}
	return i64(count)
}
