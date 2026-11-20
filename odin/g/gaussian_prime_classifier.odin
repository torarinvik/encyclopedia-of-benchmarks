package gaussian_prime_classifier

import "core:c"

MAX_COORDINATE :: i64(10_000)

gp_rational_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value % 2 == 0 do return value == 2
	divisor := i64(3)
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 2
	}
	return true
}

@(export)
gaussian_prime_classifier :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 3 do return -1
	if length != 2 do return -1
	real := values[0]
	imaginary := values[1]
	if real < -MAX_COORDINATE || real > MAX_COORDINATE ||
		imaginary < -MAX_COORDINATE || imaginary > MAX_COORDINATE do return -1
	if real == 0 && imaginary == 0 do return 0
	if real == 0 || imaginary == 0 {
		axis := if real == 0 { imaginary } else { real }
		rational := if axis < 0 { -axis } else { axis }
		if rational % 4 == 3 && gp_rational_prime(rational) do return 1
		return 0
	}
	norm := real * real + imaginary * imaginary
	if gp_rational_prime(norm) do return 1
	return 0
}
