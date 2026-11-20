package binomial_coefficient_lucas

import "core:c"

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	divisor: i64 = 2
	for divisor * divisor <= value {
		if value % divisor == 0 do return false
		divisor += 1
	}
	return true
}

power_mod :: proc(base, exponent, modulus: i64) -> i64 {
	factor := base % modulus
	remaining := exponent
	result: i64 = 1
	for remaining > 0 {
		if remaining % 2 == 1 do result = (result * factor) % modulus
		factor = (factor * factor) % modulus
		remaining /= 2
	}
	return result
}

@(export)
binomial_coefficient_lucas :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	n, k, p := values[0], values[1], values[2]
	if n < 0 || k < 0 || k > n || p < 2 || p > 1009 || !is_prime(p) do return -1

	factorial: [1010]i64
	inverse_factorial: [1010]i64
	factorial[0] = 1
	for i := i64(1); i < p; i += 1 {
		factorial[i] = (factorial[i - 1] * i) % p
	}

	inverse_factorial[p - 1] = power_mod(factorial[p - 1], p - 2, p)
	i := p - 1
	for i > 0 {
		inverse_factorial[i - 1] = (inverse_factorial[i] * i) % p
		i -= 1
	}

	remaining_n, remaining_k := n, k
	result: i64 = 1
	for remaining_n > 0 || remaining_k > 0 {
		digit_n, digit_k := remaining_n % p, remaining_k % p
		if digit_k > digit_n do return 0
		result = (result * factorial[digit_n]) % p
		result = (result * inverse_factorial[digit_k]) % p
		result = (result * inverse_factorial[digit_n - digit_k]) % p
		remaining_n /= p
		remaining_k /= p
	}
	return result
}
