@[export: 'drop3']
pub fn drop3(values &i64, length usize) i64 {
	if length > 4097 || (length > 0 && values == nil) { return -1 }
	unsafe {
		for i in 0 .. length {
			if values[i] < 0 || values[i] > 255 { return -1 }
		}
	}
	if length > 4096 { return -1 }

	offsets := [8]int{0, 5, 2, 7, 4, 1, 6, 3}
	mut output_size := i64(0)
	for _ in 0 .. 20 {
		mut input_index := 0
		mut remaining_bits := int(length) * 8
		mut phase := 0
		mut bit_buffer := u16(0)
		mut output_bits := 0
		for remaining_bits >= 3 {
			remaining_bits -= 3
			offset := offsets[phase]
			if offset < 3 {
				unsafe { bit_buffer |= u16(values[input_index]) << u16(8 - offset) }
				input_index++
			}
			code := (bit_buffer >> 13) & 7
			if code >= 4 { output_bits += 3 }
			bit_buffer <<= 3
			phase = (phase + 1) & 7
		}
		output_size = i64(output_bits >> 3)
	}
	return output_size
}
