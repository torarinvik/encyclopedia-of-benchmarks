package rgb_hsl_conversion

import "core:c"

OUTPUT_COUNT :: 4

@(export)
rgb_hsl_conversion :: proc "c" (input: [^]i64, length: c.size_t,
                                  output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	for i := 0; i < 3; i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
	if output == nil || capacity < OUTPUT_COUNT do return -2
	red := f64(input[0]) / 255.0
	green := f64(input[1]) / 255.0
	blue := f64(input[2]) / 255.0
	minimum := min(red, min(green, blue))
	maximum := max(red, max(green, blue))
	channel := 0
	if maximum == green { channel = 1 } else if maximum == blue { channel = 2 }
	luminance := (minimum + maximum) / 2.0
	saturation := 0.0
	if minimum != maximum {
		if luminance <= 0.5 { saturation = (maximum - minimum) / (maximum + minimum) }
		else { saturation = (maximum - minimum) / (2.0 - maximum - minimum) }
	}
	hue := 0.0
	if saturation != 0.0 {
		if channel == 0 { hue = (green - blue) / (maximum - minimum) }
		else if channel == 1 { hue = 2.0 + (blue - red) / (maximum - minimum) }
		else { hue = 4.0 + (red - green) / (maximum - minimum) }
	}
	hue *= 60.0
	if hue < 0.0 { hue += 360.0 }
	h := u16(hue + 0.5)
	output[0] = u8(h & 255)
	output[1] = u8(h >> 8)
	output[2] = u8(saturation * 100.0 + 0.5)
	output[3] = u8(luminance * 100.0 + 0.5)
	return i64(OUTPUT_COUNT)
}
