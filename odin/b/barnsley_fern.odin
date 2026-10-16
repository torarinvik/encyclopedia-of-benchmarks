package barnsley_fern

import "core:c"

Q12_OFFSET :: i64(10_000_000_000)
Q6_DIVISOR :: i64(1_000_000)

round_div_even :: proc "contextless" (numerator, denominator: i64) -> i64 {
	negative := numerator < 0
	magnitude := u64(numerator)
	if negative { magnitude = u64(-numerator) }
	divisor := u64(denominator)
	quotient := magnitude / divisor
	remainder := magnitude % divisor
	if remainder * 2 > divisor || (remainder * 2 == divisor && (quotient & 1) != 0) {
		quotient += 1
	}
	if negative { return -i64(quotient) }
	return i64(quotient)
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
barnsley_fern :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 { return -1 }
	iteration_value := input[0]
	if iteration_value < 1 || iteration_value > 4096 || length != c.size_t(iteration_value) { return -1 }
	iterations := int(iteration_value)
	for step := 1; step < iterations; step += 1 {
		if input[step] < 0 || input[step] >= 10_000 { return -1 }
	}
	output_length := iterations * 16
	if output == nil || capacity < c.size_t(output_length) { return -2 }

	x, y: i64 = 0, 0
	put_i64_le(output, 0, 0)
	put_i64_le(output, 8, 0)
	for step := 1; step < iterations; step += 1 {
		sample := input[step]
		a, b, c_value, d, f: i64 = 0, 0, 0, 0, 0
		if sample < 100 {
			d = 16
		} else if sample < 8_600 {
			a, b, c_value, d, f = 85, 4, -4, 85, 160
		} else if sample < 9_300 {
			a, b, c_value, d, f = 20, -26, 23, 22, 160
		} else {
			a, b, c_value, d, f = -15, 28, 26, 24, 44
		}
		next_x := round_div_even(a*x+b*y, 100)
		next_y := round_div_even(c_value*x+d*y, 100) + f*Q12_OFFSET
		x, y = next_x, next_y
		put_i64_le(output, step*16, round_div_even(x, Q6_DIVISOR))
		put_i64_le(output, step*16+8, round_div_even(y, Q6_DIVISOR))
	}
	return i64(output_length)
}
