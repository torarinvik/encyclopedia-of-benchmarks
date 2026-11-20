package miller_backward_recurrence_normalization

import "core:c"

MODULUS :: i64(998244353)
MAX_INPUT_LENGTH :: 35

mod_pow :: proc "contextless" (base_value, exponent_value: i64) -> i64 {
	base, exponent, result := base_value, exponent_value, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
miller_backward_recurrence_normalization :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_INPUT_LENGTH do return -1
	levels_value := input[0]
	if levels_value < 1 || levels_value > 8 do return -1
	levels := int(levels_value)
	if int(length) != 4*levels+2 do return -1
	for index := 1; index < int(length); index += 1 {
		if input[index] < 0 || input[index] >= MODULUS do return -1
	}
	for level := 1; level <= levels; level += 1 {
		if input[3*level] == 0 do return -1
	}

	trial: [10]i64 = {}
	trial[levels] = 1
	trial[levels+1] = 0
	for level := levels; level > 0; level -= 1 {
		a_value := input[3*level-2]
		b_value := input[3*level-1]
		c_value := input[3*level]
		positive := b_value*trial[level] % MODULUS
		negative := a_value*trial[level+1] % MODULUS
		numerator := (positive+MODULUS-negative) % MODULUS
		trial[level-1] = numerator*mod_pow(c_value, MODULUS-2) % MODULUS
	}
	lambda_start := 3*levels+1
	normalizer := i64(0)
	for index := 0; index <= levels; index += 1 {
		normalizer = (normalizer+input[lambda_start+index]*trial[index]) % MODULUS
	}
	if normalizer == 0 do return -1
	scale := mod_pow(normalizer, MODULUS-2)
	required := c.size_t(8*(levels+2))
	if output == nil || capacity < required do return -2

	store_i64_le(output, 0, levels_value)
	for index := 0; index <= levels; index += 1 {
		store_i64_le(output, c.size_t(8*(index+1)), trial[index]*scale % MODULUS)
	}
	return i64(required)
}
