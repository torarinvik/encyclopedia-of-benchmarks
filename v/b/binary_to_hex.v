module binary_to_hex

@[export: 'binary_to_hex']
pub fn binary_to_hex(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > 4096 { return -1 }
	if length > 0 && unsafe { values == nil } { return -1 }
	for index in 0 .. int(length) {
		bit := unsafe { values[index] }
		if bit != 48 && bit != 49 { return -1 }
	}

	output_length := (length + 3) / 4
	if output_length == 0 { return 0 }
	if unsafe { output == nil } || output_capacity < output_length { return -2 }

	mut first_width := length % 4
	if first_width == 0 { first_width = 4 }
	mut start := usize(0)
	unsafe {
		for group in 0 .. int(output_length) {
			width := if group == 0 { first_width } else { usize(4) }
			mut nibble := 0
			for offset in 0 .. int(width) {
				nibble = nibble * 2 + int(values[start + usize(offset)] - 48)
			}
			output[group] = u8(if nibble < 10 { 48 + nibble } else { 55 + nibble })
			start += width
		}
	}
	return i64(output_length)
}
