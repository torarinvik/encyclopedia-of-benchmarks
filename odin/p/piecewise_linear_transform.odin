package piecewise_linear_transform

import "core:c"

piecewise_linear_transform :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 256 do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < 0 || input[index] > 255 do return -1
	}
	if output == nil || capacity < length do return -2
	for index := c.size_t(0); index < length; index += 1 {
		pixel := f64(input[index])
		mapped := f64(0)
		if pixel <= 100.0 {
			mapped = (50.0 / 100.0) * pixel
		} else if pixel <= 180.0 {
			mapped = ((200.0 - 50.0) / (180.0 - 100.0)) * (pixel - 100.0) + 50.0
		} else {
			mapped = ((255.0 - 200.0) / (255.0 - 180.0)) * (pixel - 180.0) + 200.0
		}
		output[index] = u8(mapped)
	}
	return i64(length)
}
