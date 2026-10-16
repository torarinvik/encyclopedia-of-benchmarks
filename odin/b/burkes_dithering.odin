package burkes_dithering

import "core:c"

trunc_div32 :: proc "contextless" (value: i32) -> i32 {
	if value < 0 do return -((-value) / 32)
	return value / 32
}

@(export)
burkes_dithering :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 150 do return -1
	if input[0] < 1 || input[0] > 7 || input[1] < 1 || input[1] > 254 do return -1
	side := int(input[0])
	threshold := i32(input[1])
	if int(length) != 2 + 3 * side * side do return -1
	for index := 2; index < int(length); index += 1 {
		if input[index] < 0 || input[index] > 255 do return -1
	}

	stride := side + 4
	errors: [88]i32
	white_pixels: u64 = 0
	for y := 0; y < side; y += 1 {
		for x := 0; x < side; x += 1 {
			offset := 2 + 3 * (y * side + x)
			blue := i32(input[offset])
			green := i32(input[offset + 1])
			red := i32(input[offset + 2])
			gray := (114 * blue + 587 * green + 299 * red) / 1000
			adjusted := gray + errors[y * stride + x]
			white := adjusted >= threshold
			current_error := adjusted
			if white {
				white_pixels |= u64(1) << u64(y * side + x)
				current_error -= 255
			}
			errors[y * stride + x + 1] += trunc_div32(8 * current_error)
			errors[y * stride + x + 2] += trunc_div32(4 * current_error)
			errors[(y + 1) * stride + x] += trunc_div32(8 * current_error)
			errors[(y + 1) * stride + x + 1] += trunc_div32(4 * current_error)
			errors[(y + 1) * stride + x + 2] += trunc_div32(2 * current_error)
			if x >= 1 do errors[(y + 1) * stride + x - 1] += trunc_div32(4 * current_error)
			if x >= 2 do errors[(y + 1) * stride + x - 2] += trunc_div32(2 * current_error)
		}
	}
	return i64(white_pixels)
}
