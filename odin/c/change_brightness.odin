package change_brightness

import "core:c"

truncate_divide :: proc "contextless" (numerator, denominator: i64) -> i64 {
	if numerator < 0 do return -((-numerator) / denominator)
	return numerator / denominator
}
transform_channel :: proc "contextless" (channel, level, mode: i64) -> i64 {
	value := channel + level
	if mode != 0 {
		denominator := i64(255) * (259 - level)
		numerator := i64(128) * denominator + i64(259) * (level + 255) * (channel - 128)
		value = truncate_divide(numerator, denominator)
	}
	if value < 0 do return 0
	if value > 255 do return 255
	return value
}
image_point_transform :: proc "contextless" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t, mode: i64) -> i64 {
	if values == nil || length < 1 || length > 4096 do return -1
	level := values[0]
	if level < -255 || level > 255 do return -1
	channels := int(length - 1)
	for index in 0..<channels {
		if values[index + 1] < 0 || values[index + 1] > 255 do return -1
	}
	if c.size_t(channels) > output_capacity || (channels != 0 && output == nil) do return -2
	for index in 0..<channels {
		output[index] = u8(transform_channel(values[index + 1], level, mode))
	}
	return i64(channels)
}
@(export)
change_brightness :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	return image_point_transform(values, length, output, output_capacity, 0)
}
@(export)
change_contrast :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	return image_point_transform(values, length, output, output_capacity, 1)
}
