package modular_division

import "core:c"

// Fermat modular division for a bounded prime modulus.
modular_division_is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	for divisor: i64 = 2; divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

modular_division_power :: proc(base_input: i64, exponent_input: u64, modulus: i64) -> i64 {
	base := base_input % modulus
	exponent := exponent_input
	result: i64 = 1
	for exponent != 0 {
		if exponent & 1 != 0 do result = (result * base) % modulus
		exponent >>= 1
		base = (base * base) % modulus
	}
	return result
}

@(export)
modular_division :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	numerator := values[0]
	denominator := values[1]
	modulus := values[2]
	if numerator < 0 || numerator > 1000000000000 || denominator < 0 || denominator > 1000000000000 ||
		modulus < 2 || modulus > 1000000 || !modular_division_is_prime(modulus) || denominator % modulus == 0 {
		return -1
	}
	inverse := modular_division_power(denominator, u64(modulus-2), modulus)
	return ((numerator % modulus) * inverse) % modulus
}
