package steed_continued_fraction_convergents

import "core:c"

MODULUS :: i64(998244353)
MAX_INPUT_LENGTH :: 19

mod_pow :: proc "contextless" (base_value, exponent_value: i64) -> i64 {
	base, exponent, result := base_value, exponent_value, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

divisors_are_nonzero :: proc "contextless" (input: [^]i64, levels: int) -> bool {
	if input[2] == 0 do return false
	d_value := mod_pow(input[2], MODULUS-2)
	for level := 2; level <= levels; level += 1 {
		denominator := (d_value*input[2*level+1] + input[2*level]) % MODULUS
		if denominator == 0 do return false
		d_value = mod_pow(denominator, MODULUS-2)
	}
	return true
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
steed_continued_fraction_convergents :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	levels_value := input[0]
	if levels_value < 1 || levels_value > 8 do return -1
	levels := int(levels_value)
	if int(length) != 2 + 2*levels do return -1
	for index := 1; index < int(length); index += 1 {
		if input[index] < 0 || input[index] >= MODULUS do return -1
	}
	if !divisors_are_nonzero(input, levels) do return -1
	required := c.size_t(8 * (levels + 2))
	if output == nil || capacity < required do return -2

	store_i64_le(output, 0, levels_value+1)
	current := input[1]
	store_i64_le(output, 8, current)
	d_value := mod_pow(input[2], MODULUS-2)
	delta := input[3] * d_value % MODULUS
	current = (current + delta) % MODULUS
	store_i64_le(output, 16, current)
	for level := 2; level <= levels; level += 1 {
		b_value := input[2*level]
		a_value := input[2*level+1]
		denominator := (d_value*a_value + b_value) % MODULUS
		d_value = mod_pow(denominator, MODULUS-2)
		factor := (b_value*d_value + MODULUS-1) % MODULUS
		delta = factor * delta % MODULUS
		current = (current + delta) % MODULUS
		store_i64_le(output, c.size_t(8*(level+1)), current)
	}
	return i64(required)
}
