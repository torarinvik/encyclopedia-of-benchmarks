package chernick_carmichael_least_multiplier

import "core:c"

MAX_MULTIPLIER :: 950560

ccm_is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value % 2 == 0 do return value == 2
	divisor: i64 = 3
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 2
	}
	return true
}

ccm_factors_are_prime :: proc "contextless" (n, multiplier: i64) -> bool {
	if !ccm_is_prime(6 * multiplier + 1) do return false
	if !ccm_is_prime(12 * multiplier + 1) do return false

	power_of_two: i64 = 2
	factor_index: i64 = 1
	for factor_index <= n - 2 {
		if !ccm_is_prime(9 * multiplier * power_of_two + 1) do return false
		power_of_two *= 2
		factor_index += 1
	}
	return true
}

@(export)
chernick_carmichael_least_multiplier :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != c.size_t(1) do return -1
	n := input[0]
	if n < 3 || n > 9 do return -1

	step: i64 = 1
	if n > 4 do step = 1 << (n - 4)
	if n > 5 do step *= 5

	for multiplier := step; multiplier <= i64(MAX_MULTIPLIER); multiplier += step {
		if ccm_factors_are_prime(n, multiplier) do return multiplier
	}
	return -1
}
