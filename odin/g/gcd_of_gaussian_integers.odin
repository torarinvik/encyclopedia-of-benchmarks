package gcd_of_gaussian_integers

import "core:c"

MAX_T :: 8
MAX_COMPONENT :: i64(1000000)
MAX_OUTPUT_BYTES :: 64

nearest_quotient :: proc(numerator, denominator: i64) -> i64 {
	sign := i64(1)
	magnitude := numerator
	if numerator < 0 {
		sign = -1
		magnitude = -numerator
	}
	quotient := magnitude / denominator
	remainder := magnitude % denominator
	if 2 * remainder >= denominator { quotient += 1 }
	return sign * quotient
}

write_u32 :: proc(output: [^]u8, offset: int, value: u32) {
	output[offset] = u8(value)
	output[offset + 1] = u8(value >> 8)
	output[offset + 2] = u8(value >> 16)
	output[offset + 3] = u8(value >> 24)
}

@(export)
gcd_of_gaussian_integers :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 1 + 4 * MAX_T do return -1
	t64 := input[0]
	if t64 < 1 || t64 > i64(MAX_T) do return -1
	t := int(t64)
	if length != c.size_t(1 + 4 * t) do return -1

	values: [MAX_T * 4]i64
	for index := 0; index < 4 * t; index += 1 {
		value := input[index + 1]
		if value < -MAX_COMPONENT || value > MAX_COMPONENT do return -1
		values[index] = value
	}
	required := 8 * t
	if output == nil || capacity < c.size_t(required) || required > MAX_OUTPUT_BYTES do return -2

	for test := 0; test < t; test += 1 {
		ar := values[4 * test]
		ai := values[4 * test + 1]
		br := values[4 * test + 2]
		bi := values[4 * test + 3]
		for br != 0 || bi != 0 {
			denominator := br * br + bi * bi
			qr := nearest_quotient(ar * br + ai * bi, denominator)
			qi := nearest_quotient(ai * br - ar * bi, denominator)
			rr := ar - (qr * br - qi * bi)
			ri := ai - (qr * bi + qi * br)
			ar, ai, br, bi = br, bi, rr, ri
		}
		if ar != 0 || ai != 0 {
			for rotation := 0; rotation < 4 && !(ar > 0 && ai >= 0); rotation += 1 {
				old_real := ar
				ar, ai = -ai, old_real
			}
		}
		write_u32(output, 8 * test, u32(ar))
		write_u32(output, 8 * test + 4, u32(ai))
	}
	return i64(required)
}
