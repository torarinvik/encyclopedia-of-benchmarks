package pollard_p_minus_one_factorization

import "core:c"

SMALL_PRIMES :: [18]i64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61}

gcd_i64 :: proc(left_input, right_input: i64) -> i64 {
	left, right := left_input, right_input
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

pow_mod_i64 :: proc(base_input, exponent_input, modulus: i64) -> i64 {
	result: i64 = 1
	base, exponent := base_input % modulus, exponent_input
	for exponent > 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

@(export)
pollard_p_minus_one_factorization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	number, bound, initial := input[0], input[1], input[2]
	if number < 2 || number > 1_000_000_000 || bound < 2 || bound > 64 || initial < 1 || initial >= number do return -1
	divisor := gcd_i64(initial, number)
	if divisor > 1 do return divisor
	state := initial
	for prime in SMALL_PRIMES {
		if prime > bound do break
		exponent := prime
		for exponent <= bound / prime { exponent *= prime }
		state = pow_mod_i64(state, exponent, number)
		difference := state - 1
		if difference < 0 { difference = -difference }
		divisor = gcd_i64(difference, number)
		if divisor > 1 do return if divisor < number then divisor else 0
	}
	return 0
}
