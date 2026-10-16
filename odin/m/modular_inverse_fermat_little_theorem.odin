package modular_inverse_fermat_little_theorem

is_prime :: proc(value: i64) -> bool {
	if value <= 1 do return false
	for divisor: i64 = 2; divisor * divisor <= value; divisor += 1 {
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
	if a < -1_000_000 || a > 1_000_000 || m < 2 || m > 1_000_000 do return -1
	if a == 0 || a <= -m || a >= m || !is_prime(m) do return -1
	normalized := a
	for normalized < 0 {
		normalized += m
	}
	return binary_exponentiation(normalized, m - 2, m)
}
