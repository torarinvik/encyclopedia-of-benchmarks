package continued_fraction_forward_series_recurrence

import "core:c"

MODULUS :: i64(998244353)
MAX_INPUT_LENGTH :: 11

mod_pow :: proc "contextless" (base_value, exponent_value: i64) -> i64 {
	base, exponent, result := base_value, exponent_value, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

next_numerator :: proc "contextless" (coefficient, rho: i64) -> i64 {
	return coefficient * ((rho + 1) % MODULUS) % MODULUS
}

divisors_are_nonzero :: proc "contextless" (input: [^]i64, count: int) -> bool {
	rho := i64(0)
	for index := 1; index < count; index += 1 {
		top := next_numerator(input[index+1], rho)
		denominator := (1 + MODULUS - top) % MODULUS
		if denominator == 0 do return false
		rho = top * mod_pow(denominator, MODULUS-2) % MODULUS
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
continued_fraction_forward_series_recurrence :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value < 2 || count_value > 9 do return -1
	count := int(count_value)
	if int(length) != count + 1 do return -1
	for index := 1; index <= count; index += 1 {
		if input[index] < 0 || input[index] >= MODULUS do return -1
	}
	if !divisors_are_nonzero(input, count) do return -1
	required := c.size_t(8 * (count + 1))
	if output == nil || capacity < required do return -2

	store_i64_le(output, 0, count_value)
	rho, term, total := i64(0), input[1], input[1]
	store_i64_le(output, 8, total)
	for index := 1; index < count; index += 1 {
		top := next_numerator(input[index+1], rho)
		denominator := (1 + MODULUS - top) % MODULUS
		rho = top * mod_pow(denominator, MODULUS-2) % MODULUS
		term = rho * term % MODULUS
		total = (total + term) % MODULUS
		store_i64_le(output, c.size_t(8*(index+1)), total)
	}
	return i64(required)
}
