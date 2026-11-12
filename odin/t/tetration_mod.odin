package tetration_mod

import "core:c"

MAX_VALUE :: i64(1_000_000_000)

totient :: proc "contextless" (value: i64) -> i64 {
	result := value
	remaining := value
	if remaining % 2 == 0 {
		result -= result / 2
		for remaining % 2 == 0 { remaining /= 2 }
	}
	factor := i64(3)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			result -= result / factor
			for remaining % factor == 0 { remaining /= factor }
		}
		factor += 2
	}
	if remaining > 1 { result -= result / remaining }
	return result
}

power_capped :: proc "contextless" (base, exponent_input, cap: i64) -> i64 {
	result := i64(1)
	factor := min(base, cap)
	exponent := exponent_input
	for exponent > 0 {
		if exponent % 2 != 0 {
			result *= factor
			if result >= cap do return cap
		}
		exponent /= 2
		if exponent > 0 {
			factor *= factor
			if factor >= cap do factor = cap
		}
	}
	return result
}

tower_capped :: proc "contextless" (base, height_input, cap: i64) -> i64 {
	if height_input == 0 do return min(i64(1), cap)
	if base == 0 do return (height_input % 2 == 0 ? i64(1) : i64(0))
	if base == 1 do return min(i64(1), cap)
	value := i64(1)
	if value >= cap do return cap
	height := height_input
	for height > 0 {
		value = power_capped(base, value, cap)
		if value >= cap do return cap
		height -= 1
	}
	return value
}

modular_power :: proc "contextless" (base_input, exponent_input, modulus: i64) -> i64 {
	result := i64(1) % modulus
	base := base_input % modulus
	exponent := exponent_input
	for exponent > 0 {
		if exponent % 2 != 0 { result = (result * base) % modulus }
		exponent /= 2
		base = (base * base) % modulus
	}
	return result
}

tetration :: proc "contextless" (base, height, modulus: i64) -> i64 {
	if modulus == 1 do return 0
	if height == 0 do return i64(1) % modulus
	if height == 1 do return base % modulus
	exponent_modulus := totient(modulus)
	exponent := tetration(base, height - 1, exponent_modulus)
	if tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus {
		exponent += exponent_modulus
	}
	return modular_power(base, exponent, modulus)
}

// Packed input [A, B, M], where B is tower height.
@(export)
tetration_mod :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	base, height, modulus := values[0], values[1], values[2]
	if base < 0 || base > MAX_VALUE || height < 0 || height > MAX_VALUE ||
		modulus < 1 || modulus > MAX_VALUE do return -1
	return tetration(base, height, modulus)
}
