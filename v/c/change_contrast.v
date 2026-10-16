module change_brightness

fn truncate_divide(numerator i64, denominator i64) i64 {
	if numerator < 0 { return -((-numerator) / denominator) }
	return numerator / denominator
}
fn transform_channel(channel i64, level i64, mode i64) i64 {
	mut value := channel + level
	if mode != 0 {
		denominator := i64(255) * (259 - level)
		numerator := i64(128) * denominator + i64(259) * (level + 255) * (channel - 128)
		value = truncate_divide(numerator, denominator)
	}
	if value < 0 { return 0 }
	if value > 255 { return 255 }
	return value
}
fn image_point_transform(values &i64, length usize, output &u8, output_capacity usize, mode i64) i64 {
	if length < 1 || length > 4096 { return -1 }
	level := unsafe { values[0] }
	if level < -255 || level > 255 { return -1 }
	channels := int(length - 1)
	for index in 0 .. channels {
		pixel := unsafe { values[index + 1] }
		if pixel < 0 || pixel > 255 { return -1 }
	}
	if usize(channels) > output_capacity { return -2 }
	unsafe {
		for index in 0 .. channels {
			output[index] = u8(transform_channel(values[index + 1], level, mode))
		}
	}
	return i64(channels)
}
@[export: 'change_brightness']
pub fn change_brightness(values &i64, length usize, output &u8, output_capacity usize) i64 {
	return image_point_transform(values, length, output, output_capacity, 0)
}
@[export: 'change_contrast']
pub fn change_contrast(values &i64, length usize, output &u8, output_capacity usize) i64 {
	return image_point_transform(values, length, output, output_capacity, 1)
}
