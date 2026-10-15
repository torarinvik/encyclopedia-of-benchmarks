package z_function

import "core:c"

@(export)
z_function :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if length > 256 || (length > 0 && input == nil) do return -1
	for i := 0; i < int(length); i += 1 {
		if input[i] < 0 || input[i] > 127 do return -1
	}
	required := length * 8
	if capacity < required || (required > 0 && output == nil) do return -2

	var z: [256]i64
	left, right: c.size_t = 0, 0
	for i := c.size_t(1); i < length; i += 1 {
		if i <= right {
			prior, window := c.size_t(z[i-left]), right-i+1
			if window < prior do z[i] = i64(window) else z[i] = i64(prior)
		}
		for i+c.size_t(z[i]) < length && input[c.size_t(z[i])] == input[i+c.size_t(z[i])] {
			z[i] += 1
		}
		if i+c.size_t(z[i]) > right+1 {
			left = i
			right = i+c.size_t(z[i])-1
		}
	}
	for i := c.size_t(0); i < length; i += 1 {
		bits := transmute(u64)z[i]
		for byte := 0; byte < 8; byte += 1 {
			output[8*int(i)+byte] = u8(bits >> u64(8*byte))
		}
	}
	return i64(required)
}
