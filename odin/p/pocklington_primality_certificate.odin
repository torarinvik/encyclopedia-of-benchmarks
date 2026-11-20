package pocklington_primality_certificate

import "core:c"

MAX_N :: i64(65535)
MAX_FACTORS :: i64(6)
MAX_EXPONENT :: i64(16)
MAX_LENGTH :: 22

gcd_i64 :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 do return false
		if divisor == 2 do divisor = 3 else divisor += 2
	}
	return true
}

pow_mod :: proc(base_value, exponent_value, modulus: i64) -> i64 {
	result := i64(1)
	factor := base_value % modulus
	exponent := exponent_value
	for exponent > 0 {
		if (exponent & 1) != 0 do result = (result * factor) % modulus
		factor = (factor * factor) % modulus
		exponent >>= 1
	}
	return result
}

verify_certificate :: proc(values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_LENGTH) do return -1
	n := values[0]
	count := values[1]
	if n < 3 || n > MAX_N || count < 1 || count > MAX_FACTORS do return -1
	if length != c.size_t(3 + 3 * count) do return -1

	factored_part := i64(1)
	previous_prime := i64(1)
	for index := 0; index < int(count); index += 1 {
		offset := 2 + 3 * index
		prime := values[offset]
		exponent := values[offset + 1]
		witness := values[offset + 2]
		if prime <= previous_prime || prime < 2 || exponent < 1 || exponent > MAX_EXPONENT || witness < 1 || witness >= n || !is_prime(prime) do return -1
		previous_prime = prime
		for power_index := i64(0); power_index < exponent; power_index += 1 {
			if factored_part > (n - 1) / prime do return -1
			factored_part *= prime
		}
	}
	cofactor := values[2 + 3 * int(count)]
	if cofactor < 1 || cofactor >= n || factored_part * cofactor != n - 1 do return -1
	if factored_part * factored_part <= n do return 0

	for index := 0; index < int(count); index += 1 {
		offset := 2 + 3 * index
		prime := values[offset]
		witness := values[offset + 2]
		if pow_mod(witness, n - 1, n) != 1 do return 0
		reduced := pow_mod(witness, (n - 1) / prime, n)
		difference := (reduced + n - 1) % n
		if gcd_i64(difference, n) != 1 do return 0
	}
	return 1
}

@(export)
pocklington_primality_certificate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	return verify_certificate(input, length)
}
