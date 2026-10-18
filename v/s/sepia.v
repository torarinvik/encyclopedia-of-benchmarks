@[export: 'sepia']
pub fn sepia(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 196 { return -1 }
		height, width, factor := input[0], input[1], input[2]
		if height < 1 || height > 8 || width < 1 || width > 8 || factor < 0 || factor > 255 { return -1 }
		pixels := int(height * width)
		if input_length != usize(3 + 3 * pixels) { return -1 }
		for index in 0 .. 3 * pixels {
			channel := input[3 + index]
			if channel != 0 && channel != 64 && channel != 128 && channel != 255 { return -1 }
		}

		mut staged := [192]u8{}
		for pixel in 0 .. pixels {
			offset := 3 + 3 * pixel
			blue, green, red := f64(input[offset]), f64(input[offset + 1]), f64(input[offset + 2])
			gray := i64(0.2126 * red + 0.587 * green + 0.114 * blue)
			staged[3 * pixel] = u8(gray)
			staged[3 * pixel + 1] = u8(if gray + factor > 255 { 255 } else { gray + factor })
			staged[3 * pixel + 2] = u8(if gray + 2 * factor > 255 { 255 } else { gray + 2 * factor })
		}

		output_bytes := 3 * pixels
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
