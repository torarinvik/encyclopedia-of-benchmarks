package prime_modulus_p_free_factorial

import "core:c"

MAX_PRIME :: 1009

pff_is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	divisor: i64 = 2
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 1
	}
	return true
}

@(export)
prime_modulus_p_free_factorial :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != c.size_t(2) do return -1
	n := input[0]
	prime := input[1]
	if n < 0 || prime < 2 || prime > i64(MAX_PRIME) do return -1
	if !pff_is_prime(prime) do return -1

	prime_size := int(prime)
	factorial: [MAX_PRIME]i64 = {}
	factorial[0] = 1
	for value := 1; value < prime_size; value += 1 {
		factorial[value] = factorial[value - 1] * i64(value) % prime
	}

	result: i64 = 1
	remaining := n
	for remaining > 0 {
		quotient := remaining / prime
		residue := int(remaining % prime)
		block := factorial[residue]
		if quotient % 2 != 0 do block = (prime - block) % prime
		result = result * block % prime
		remaining = quotient
	}
	return result
}
