package factorial_last_nonzero_digit

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 2

digit_factor :: proc(digit: i64) -> i64 {
	if digit == 0 || digit == 1 do return 1
	if digit == 2 do return 2
	if digit == 3 do return 6
	return 4
}

two_power_mod_10 :: proc(exponent_mod_four: i64) -> i64 {
	if exponent_mod_four == 0 do return 1
	if exponent_mod_four == 1 do return 2
	if exponent_mod_four == 2 do return 4
	return 8
}

@(export)
factorial_last_nonzero_digit :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	if length != 1 || input[0] < 0 do return -1

	n := input[0]
	result := i64(1)
	for n >= 5 {
		quotient := n / 5
		remainder := n % 5
		result = result * digit_factor(remainder) % 10
		result = result * two_power_mod_10(quotient % 4) % 10
		n = quotient
	}
	return result * digit_factor(n) % 10
}
