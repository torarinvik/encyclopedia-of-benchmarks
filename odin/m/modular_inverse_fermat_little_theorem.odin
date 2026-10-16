package modular_inverse_fermat_little_theorem

import "core:runtime"

is_prime :: proc(value: i64) -> bool {
	if value <= 1 do return false
	for divisor: i64 = 2; divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

binary_exponentiation :: proc(base_input, exponent_input, modulus: i64) -> i64 {
	base := base_input % modulus
	exponent := exponent_input
	result: i64 = 1
	for exponent > 0 {
		if exponent % 2 != 0 do result = result * base % modulus
		base = base * base % modulus
		exponent /= 2
	}
	return result
}

@(export)
modular_inverse_fermat_little_theorem :: proc "c" (a, m: i64) -> i64 {
	context = runtime.default_context()
	if a < 1 || a > 1_000_000 || m < 2 || m > 1_000_000 do return -1
	if a % m == 0 || !is_prime(m) do return -1
	return binary_exponentiation(a, m - 2, m)
}
