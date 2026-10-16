package color_contrast_ratio

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300

component :: proc(channel: i64) -> f64 {
	srgb := f64(channel) / 255.0
	if srgb <= 0.03928 do return srgb / 12.92
	return math.pow_f64((srgb + 0.055) / 1.055, 2.4)
}

luminance :: proc(red, green, blue: i64) -> f64 {
	return 0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue)
}

@(export)
color_contrast_ratio :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 6 do return INVALID_RESULT
	for i in 0 ..< 6 {
		if values[i] < 0 || values[i] > 255 do return INVALID_RESULT
	}
	first := luminance(values[0], values[1], values[2])
	second := luminance(values[3], values[4], values[5])
	if first > second do return (first + 0.05) / (second + 0.05)
	return (second + 0.05) / (first + 0.05)
}
