package rgb_hsv_conversion
import "core:c"

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
	bits := transmute(u64)value
	for i := 0; i < 8; i += 1 { output[offset + usize(i)] = u8(bits >> u64(8 * i)) }
}

@(export)
rgb_hsv_conversion :: proc "c" (input: [^]i64, length: c.size_t,
                                  output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	for i := 0; i < 3; i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
	if output == nil || capacity < 24 do return -2
	red, green, blue := f64(input[0])/255.0, f64(input[1])/255.0, f64(input[2])/255.0
	value := max(max(red, green), blue)
	chroma := value - min(min(red, green), blue)
	saturation := 0.0
	if value != 0.0 do saturation = chroma / value
	hue := 0.0
	if chroma != 0.0 {
		if value == red do hue = 60.0 * (0.0 + (green - blue) / chroma)
		else if value == green do hue = 60.0 * (2.0 + (blue - red) / chroma)
		else do hue = 60.0 * (4.0 + (red - green) / chroma)
	}
	hue += 360.0
	if hue >= 360.0 do hue -= 360.0
	put_f64_le(output, 0, hue)
	put_f64_le(output, 8, saturation)
	put_f64_le(output, 16, value)
	return 24
}
