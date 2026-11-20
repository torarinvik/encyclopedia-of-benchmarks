package domain_coloring

import "core:c"

MAX_OUTPUT_BYTES :: 768

phase_hue :: proc "contextless" (real_part, imaginary_part: i64) -> i64 {
	if real_part == 0 && imaginary_part == 0 do return 0
	abs_real := if real_part < 0 then -real_part else real_part
	abs_imaginary := if imaginary_part < 0 then -imaginary_part else imaginary_part
	high := max(abs_real, abs_imaginary)
	low := min(abs_real, abs_imaginary)
	step := 192 * low / high
	hue: i64
	if imaginary_part >= 0 {
		if real_part >= 0 do hue = if abs_real >= abs_imaginary then step else 384 - step
		else do hue = if abs_real < abs_imaginary then 384 + step else 768 - step
	} else if real_part < 0 {
		hue = if abs_real >= abs_imaginary then 768 + step else 1152 - step
	} else {
		hue = if abs_real < abs_imaginary then 1152 + step else 1536 - step
	}
	return if hue == 1536 then 0 else hue
}

store_pixel :: proc "contextless" (pixels: ^[MAX_OUTPUT_BYTES]u8,
	offset: usz, hue, magnitude_16: i64) {
	value := 128 + 8 * (magnitude_16 % 16)
	sector := hue / 256
	fraction := hue % 256
	rising := u8(value * fraction / 255)
	falling := u8(value * (255 - fraction) / 255)
	bright := u8(value)
	red, green, blue: u8 = 0, 0, 0
	switch sector {
	case 0: red = bright; green = rising
	case 1: red = falling; green = bright
	case 2: green = bright; blue = rising
	case 3: green = falling; blue = bright
	case 4: red = rising; blue = bright
	case: red = bright; blue = falling
	}
	pixels[offset] = red
	pixels[offset + 1] = green
	pixels[offset + 2] = blue
}

@(export)
domain_coloring :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 6 do return -1
	width_value, height_value := input[0], input[1]
	x_start, y_start := input[2], input[3]
	x_step, y_step := input[4], input[5]
	if width_value < 1 || width_value > 16 || height_value < 1 || height_value > 16 ||
		x_start < -32 || x_start > 32 || y_start < -32 || y_start > 32 ||
		x_step < -8 || x_step > 8 || y_step < -8 || y_step > 8 do return -1
	x_end := x_start + (width_value - 1) * x_step
	y_end := y_start + (height_value - 1) * y_step
	if x_end < -32 || x_end > 32 || y_end < -32 || y_end > 32 do return -1

	width, height := usz(width_value), usz(height_value)
	byte_count := 3 * width * height
	var rendered: [MAX_OUTPUT_BYTES]u8
	offset: usz = 0
	for row: usz = 0; row < height; row += 1 {
		y_q := y_start + i64(row) * y_step
		for column: usz = 0; column < width; column += 1 {
			x_q := x_start + i64(column) * x_step
			x_squared, y_squared := x_q*x_q, y_q*y_q
			store_pixel(&rendered, offset, phase_hue(x_squared-y_squared, 2*x_q*y_q), x_squared+y_squared)
			offset += 3
		}
	}
	if output == nil || output_capacity < byte_count do return -2
	for index: usz = 0; index < byte_count; index += 1 { output[index] = rendered[index] }
	return i64(byte_count)
}
