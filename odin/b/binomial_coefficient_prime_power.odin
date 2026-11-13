package binomial_coefficient_prime_power

import "core:c"

MAX_QUERIES :: 32
MAX_N :: 128
MAX_PARSEABLE :: 68
MAX_MODULUS :: i64(1_000_000_000)

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

pow_mod :: proc(base_value, exponent_value, modulus: i64) -> i64 {
	base, exponent := base_value, exponent_value
	result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 do result = result * base % modulus
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@(export)
binomial_coefficient_prime_power :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE do return -1
	p, e, q_value := input[0], input[1], input[2]
	if p < 2 || p > 31 || !is_prime(p) || e < 1 || e > 8 || q_value < 0 || q_value > MAX_QUERIES do return -1
	modulus := i64(1)
	for index := i64(0); index < e; index += 1 {
		modulus *= p
		if modulus > MAX_MODULUS do return -1
	}
	q := int(q_value)
	if length != c.size_t(3 + 2 * q) do return -1
	for i := 0; i < q; i += 1 {
		n, k := input[3 + 2 * i], input[4 + 2 * i]
		if n < 0 || n > MAX_N || k < 0 || k > n do return -1
	}
	if q == 0 do return 0
	required := 4 * q
	if output == nil || capacity < c.size_t(required) do return -2

	var unit_prefix: [MAX_N + 1]i64
	var p_free_factorial: [MAX_N + 1]i64
	var valuation: [MAX_N + 1]u16
	var residues: [MAX_QUERIES]u32
	unit_prefix[0], p_free_factorial[0] = 1, 1
	for n := 1; n <= MAX_N; n += 1 {
		factor := i64(n)
		if n % int(p) == 0 do factor = 1
		unit_prefix[n] = unit_prefix[n - 1] * factor % modulus
		p_free_factorial[n] = unit_prefix[n] * p_free_factorial[n / int(p)] % modulus
		valuation[n] = u16(n / int(p) + int(valuation[n / int(p)]))
	}
	phi := modulus / p * (p - 1)
	for i := 0; i < q; i += 1 {
		n, k := int(input[3 + 2 * i]), int(input[4 + 2 * i])
		p_power := int(valuation[n]) - int(valuation[k]) - int(valuation[n - k])
		if p_power < int(e) {
			denominator := p_free_factorial[k] * p_free_factorial[n - k] % modulus
			inverse := pow_mod(denominator, phi - 1, modulus)
			prime_factor := pow_mod(p, i64(p_power), modulus)
			residues[i] = u32(p_free_factorial[n] * inverse % modulus * prime_factor % modulus)
		}
	}
	for i := 0; i < q; i += 1 {
		for byte := 0; byte < 4; byte += 1 {
			output[4 * i + byte] = u8(residues[i] >> (8 * byte))
		}
	}
	return i64(required)
}
