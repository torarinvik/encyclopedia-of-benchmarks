module common_characters_frequency_quotient

@[export: 'common_characters_frequency_quotient']
pub fn common_characters_frequency_quotient(input &i64, length usize, output &u8, capacity usize) i64 {
	if input == nil || length == 0 || length > 1041 { return -1 }
	string_count := unsafe { input[0] }
	if string_count < 0 || string_count > 16 { return -1 }
	mut counts := [26]i64{}
	mut offset := 1
	mut total := 0
	for _ in 0 .. int(string_count) {
		if offset >= length { return -1 }
		string_length := unsafe { input[offset] }
		offset++
		if string_length < 0 || string_length > 64 || usize(string_length) > length - offset { return -1 }
		for _ in 0 .. int(string_length) {
			value := unsafe { input[offset] }
			offset++
			if value < 97 || value > 122 { return -1 }
			counts[int(value - 97)]++
		}
		total += int(string_length)
		if total > 512 { return -1 }
	}
	if offset != length { return -1 }
	mut used := 0
	if string_count > 0 {
		for frequency in counts { used += int(frequency / string_count) }
	}
	if used > capacity || (used > 0 && output == nil) { return -2 }
	mut output_offset := 0
	if string_count > 0 {
		for letter, frequency in counts {
			copies := frequency / string_count
			for _ in 0 .. int(copies) {
				unsafe { output[output_offset] = u8(97 + letter) }
				output_offset++
			}
		}
	}
	return i64(used)
}
