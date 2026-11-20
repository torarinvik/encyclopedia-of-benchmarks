module domain_coloring

const max_output_bytes = 768

fn phase_hue(real_part i64, imaginary_part i64) i64 {
	if real_part == 0 && imaginary_part == 0 { return 0 }
	abs_real := if real_part < 0 { -real_part } else { real_part }
	abs_imaginary := if imaginary_part < 0 { -imaginary_part } else { imaginary_part }
	high := if abs_real > abs_imaginary { abs_real } else { abs_imaginary }
	low := if abs_real < abs_imaginary { abs_real } else { abs_imaginary }
	step := i64(192) * low / high
	mut hue := i64(0)
	if imaginary_part >= 0 {
		if real_part >= 0 {
			hue = if abs_real >= abs_imaginary { step } else { 384 - step }
		} else {
			hue = if abs_real < abs_imaginary { 384 + step } else { 768 - step }
		}
	} else if real_part < 0 {
		hue = if abs_real >= abs_imaginary { 768 + step } else { 1152 - step }
	} else {
		hue = if abs_real < abs_imaginary { 1152 + step } else { 1536 - step }
	}
	return if hue == 1536 { 0 } else { hue }
}

fn store_pixel(mut pixels [max_output_bytes]u8, offset int, hue i64, magnitude_16 i64) {
	value := i64(128) + 8 * (magnitude_16 % 16)
	sector := hue / 256
	fraction := hue % 256
	rising := u8(value * fraction / 255)
	falling := u8(value * (255 - fraction) / 255)
	bright := u8(value)
	mut red := u8(0)
	mut green := u8(0)
	mut blue := u8(0)
	match sector {
		0 { red = bright; green = rising }
		1 { red = falling; green = bright }
		2 { green = bright; blue = rising }
		3 { green = falling; blue = bright }
		4 { red = rising; blue = bright }
		else { red = bright; blue = falling }
	}
	pixels[offset] = red
	pixels[offset + 1] = green
	pixels[offset + 2] = blue
}

@[export: 'domain_coloring']
pub fn domain_coloring(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 6 { return -1 }
	width_value := unsafe { input[0] }
	height_value := unsafe { input[1] }
	x_start := unsafe { input[2] }
	y_start := unsafe { input[3] }
	x_step := unsafe { input[4] }
	y_step := unsafe { input[5] }
	if width_value < 1 || width_value > 16 || height_value < 1 || height_value > 16 ||
		x_start < -32 || x_start > 32 || y_start < -32 || y_start > 32 ||
		x_step < -8 || x_step > 8 || y_step < -8 || y_step > 8 { return -1 }
	x_end := x_start + (width_value - 1) * x_step
	y_end := y_start + (height_value - 1) * y_step
	if x_end < -32 || x_end > 32 || y_end < -32 || y_end > 32 { return -1 }

	width := int(width_value)
	height := int(height_value)
	byte_count := 3 * width * height
	mut rendered := [max_output_bytes]u8{}
	mut offset := 0
	for row in 0 .. height {
		y_q := y_start + i64(row) * y_step
		for column in 0 .. width {
			x_q := x_start + i64(column) * x_step
			x_squared := x_q * x_q
			y_squared := y_q * y_q
			store_pixel(mut rendered, offset, phase_hue(x_squared-y_squared, 2*x_q*y_q), x_squared+y_squared)
			offset += 3
		}
	}
	if unsafe { output == nil } || output_capacity < usize(byte_count) { return -2 }
	for index in 0 .. byte_count { unsafe { output[index] = rendered[index] } }
	return i64(byte_count)
}
