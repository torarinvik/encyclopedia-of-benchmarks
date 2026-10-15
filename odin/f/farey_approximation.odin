package farey_approximation

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
farey_approximation :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	decimal_millionths := values[0]
	repeat := values[1]
	if decimal_millionths < 1 || decimal_millionths > 999999 || repeat < 1 || repeat > 20 do return -1
	if output == nil || output_capacity < 16 do return -2

	decimal := f64(decimal_millionths) / 1_000_000.0
	a, b, c_value, d := i64(0), i64(1), i64(1), i64(1)
	numerator, denominator := i64(0), i64(0)
	for iteration := i64(0); iteration < repeat; iteration += 1 {
		numerator = a + c_value
		denominator = b + d
		if decimal > f64(numerator) / f64(denominator) {
			a, b = numerator, denominator
		} else {
			c_value, d = numerator, denominator
		}
	}
	store_i64_le(output, 0, numerator)
	store_i64_le(output, 8, denominator)
	return 16
}
