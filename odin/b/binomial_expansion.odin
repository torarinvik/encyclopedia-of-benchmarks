package binomial_expansion

import "core:c"

MAX_EXPONENT :: 31
INVALID_RESULT :: i64(-9223372036854775807 - 1)

integer_power :: proc(base, exponent: i64) -> i64 {
	result := i64(1)
	for index := i64(0); index < exponent; index += 1 {
		result *= base
	}
	return result
}

binomial_coefficient :: proc(n, k: i64) -> i64 {
	var coefficients: [32]i64
	coefficients[0] = 1
	for row := i64(1); row <= n; row += 1 {
		column := min(row, k)
		for column > 0 {
			coefficients[column] += coefficients[column - 1]
			column -= 1
		}
	}
	return coefficients[k]
}

@(export)
binomial_expansion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return INVALID_RESULT
	a, b, exponent := input[0], input[1], input[2]
	if a < -2 || a > 2 || b < -2 || b > 2 || exponent < 0 || exponent > MAX_EXPONENT do return INVALID_RESULT

	result := i64(0)
	for index := i64(0); index <= exponent; index += 1 {
		result += binomial_coefficient(exponent, index) *
			integer_power(a, exponent-index) * integer_power(b, index)
	}
	return result
}
