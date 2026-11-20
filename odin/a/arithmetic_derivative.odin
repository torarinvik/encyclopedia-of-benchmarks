package arithmetic_derivative

import "core:c"

MAX_N :: i64(1_000_000_000_000)
MAX_PARSEABLE_LENGTH :: 2

ad_from_factors :: proc(value: i64) -> i64 {
	if value < 2 do return 0
	original := value
	remaining := value
	derivative: i64 = 0
	factor: i64 = 2
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			exponent: i64 = 0
			for remaining % factor == 0 {
				remaining /= factor
				exponent += 1
			}
			derivative += (original / factor) * exponent
		}
		if factor == 2 do factor = 3
		else do factor += 2
	}
	if remaining > 1 do derivative += original / remaining
	return derivative
}

@(export)
arithmetic_derivative :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	if length != 1 do return -1
	n := input[0]
	if n < 0 || n > MAX_N do return -1
	return ad_from_factors(n)
}
