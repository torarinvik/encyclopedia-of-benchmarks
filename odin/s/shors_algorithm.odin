package shors_algorithm

import "core:c"

MIN_MODULUS :: i64(2)
MAX_MODULUS :: i64(255)
MIN_ATTEMPTS :: i64(1)
MAX_ATTEMPTS :: i64(16)
INVALID_RESULT :: i64 = -1

gcd_i64 :: proc(a_input, b_input: i64) -> i64 {
	a := a_input
	b := b_input
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

@(export)
shors_algorithm :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 3 || length > 19 do return INVALID_RESULT
	modulus := packed[0]
	attempts := packed[1]
	if modulus < MIN_MODULUS || modulus > MAX_MODULUS || attempts < MIN_ATTEMPTS || attempts > MAX_ATTEMPTS || length != c.size_t(2 + attempts) do return INVALID_RESULT
	for index := i64(0); index < attempts; index += 1 {
		base := packed[2 + index]
		if base < 2 || base > modulus do return INVALID_RESULT
	}

	for index := i64(0); index < attempts; index += 1 {
		base := packed[2 + index]
		common := gcd_i64(base, modulus)
		if common != 1 do return common
		order := i64(1)
		power := base % modulus
		for power != 1 && order < modulus - 1 {
			power = (power * base) % modulus
			order += 1
		}
		if power != 1 do return INVALID_RESULT
		if order % 2 == 1 do continue

		half_power := i64(1)
		for exponent := i64(0); exponent < order / 2; exponent += 1 {
			half_power = (half_power * base) % modulus
		}
		upper := half_power + 1
		lower := half_power - 1
		if upper % modulus == 0 || lower % modulus == 0 do continue
		upper_gcd := gcd_i64(upper, modulus)
		if upper_gcd != 1 do return upper_gcd
		return gcd_i64(lower, modulus)
	}
	return INVALID_RESULT
}
