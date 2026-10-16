module burkes_dithering

fn trunc_div32(value i32) i32 {
	if value < 0 {
		return -((-value) / 32)
	}
	return value / 32
}

@[export: 'burkes_dithering']
pub fn burkes_dithering(input &i64, length usize) i64 {
	if length < 3 || length > 150 { return -1 }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > 7 || input[1] < 1 || input[1] > 254 {
			return -1
		}
		side := int(input[0])
		threshold := i32(input[1])
		if int(length) != 2 + 3 * side * side { return -1 }
		for index in 2 .. int(length) {
			if input[index] < 0 || input[index] > 255 { return -1 }
		}

		stride := side + 4
		mut errors := [88]i32{}
		mut white_pixels := u64(0)
		for y in 0 .. side {
			for x in 0 .. side {
				offset := 2 + 3 * (y * side + x)
				blue := i32(input[offset])
				green := i32(input[offset + 1])
				red := i32(input[offset + 2])
				gray := (114 * blue + 587 * green + 299 * red) / 1000
				adjusted := gray + errors[y * stride + x]
				white := adjusted >= threshold
				current_error := adjusted - if white { i32(255) } else { i32(0) }
				if white { white_pixels |= u64(1) << (y * side + x) }
				errors[y * stride + x + 1] += trunc_div32(8 * current_error)
				errors[y * stride + x + 2] += trunc_div32(4 * current_error)
				errors[(y + 1) * stride + x] += trunc_div32(8 * current_error)
				errors[(y + 1) * stride + x + 1] += trunc_div32(4 * current_error)
				errors[(y + 1) * stride + x + 2] += trunc_div32(2 * current_error)
				if x >= 1 { errors[(y + 1) * stride + x - 1] += trunc_div32(4 * current_error) }
				if x >= 2 { errors[(y + 1) * stride + x - 2] += trunc_div32(2 * current_error) }
			}
		}
		return i64(white_pixels)
	}
}
