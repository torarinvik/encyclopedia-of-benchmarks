package euler_alternating_series_transform

import "core:c"

MAX_TERMS :: 16
MAX_WORDS :: 18
VALUE_LIMIT :: 1_000_000
OUTPUT_BYTES :: 16

euler_gcd :: proc "contextless" (left_value, right_value: u64) -> u64 {
	left, right := left_value, right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

euler_store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
euler_alternating_series_transform :: proc "c" (values: [^]i64,
		length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_WORDS do return -1
	n_value := values[0]
	if n_value < 1 || n_value > MAX_TERMS || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	for index := 0; index < n; index += 1 {
		if values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT do return -1
	}
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2

	numerator: i64 = 0
	for order := 0; order < n; order += 1 {
		difference: i64 = 0
		coefficient: i64 = 1
		for index := 0; index <= order; index += 1 {
			term := values[order - index + 1]
			if index % 2 == 0 {
				difference += coefficient * term
			} else {
				difference -= coefficient * term
			}
			if index < order {
				coefficient = coefficient * i64(order - index) / i64(index + 1)
			}
		}
		weight := i64(1) << (n - order - 1)
		weighted := difference * weight
		if order % 2 == 0 {
			numerator += weighted
		} else {
			numerator -= weighted
		}
	}

	denominator := i64(1) << n
	magnitude: u64
	if numerator < 0 {
		magnitude = u64(-numerator)
	} else {
		magnitude = u64(numerator)
	}
	divisor := euler_gcd(magnitude, u64(denominator))
	numerator /= i64(divisor)
	denominator /= i64(divisor)
	euler_store_i64(output, 0, numerator)
	euler_store_i64(output, 8, denominator)
	return i64(OUTPUT_BYTES)
}
