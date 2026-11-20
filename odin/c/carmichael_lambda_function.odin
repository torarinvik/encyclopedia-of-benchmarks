// Carmichael's universal exponent by prime-power factorization.
package carmichael_lambda_function

import "core:c"

MAX_N :: i64(1024)
MAX_PARSEABLE_LENGTH :: 2

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

lcm_i64 :: proc(left, right: i64) -> i64 {
	return left / gcd_i64(left, right) * right
}

prime_power_lambda :: proc(prime: i64, exponent: int, power: i64) -> i64 {
	if prime == 2 {
		if exponent == 1 do return 1
		if exponent == 2 do return 2
		return power / 4
	}
	return (power / prime) * (prime - 1)
}

factorization_lambda :: proc(n: i64) -> i64 {
	if n == 1 do return 1
	remaining := n
	result := i64(1)
	prime := i64(2)
	for prime * prime <= remaining {
		if remaining % prime != 0 {
			if prime == 2 do prime = 3 else prime += 2
			continue
		}
		exponent := 0
		power := i64(1)
		for remaining % prime == 0 {
			remaining /= prime
			power *= prime
			exponent += 1
		}
		component := prime_power_lambda(prime, exponent, power)
		result = lcm_i64(result, component)
		if prime == 2 do prime = 3 else prime += 2
	}
	if remaining > 1 do result = lcm_i64(result, remaining - 1)
	return result
}

@(export)
carmichael_lambda_function :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	n := input[0]
	if n < 1 || n > MAX_N || length != 1 do return -1
	return factorization_lambda(n)
}
