package divide_two_integers

import "core:c"

INVALID_RESULT :: i64(-2147483649)

// Truncate signed 32-bit division toward zero using doubled divisor chunks.
@(export)
divide_two_integers :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return INVALID_RESULT
	dividend := values[0]
	divisor := values[1]
	if dividend < -2147483648 || dividend > 2147483647 ||
		divisor < -2147483648 || divisor > 2147483647 || divisor == 0 {
		return INVALID_RESULT
	}

	remaining := dividend
	if remaining < 0 do remaining = -remaining
	divisor_magnitude := divisor
	if divisor_magnitude < 0 do divisor_magnitude = -divisor_magnitude
	quotient := i64(0)
	for shift := 31; shift >= 0; shift -= 1 {
		shift_amount := u32(shift)
		if divisor_magnitude <= (remaining >> shift_amount) {
			remaining -= divisor_magnitude << shift_amount
			quotient += i64(1) << shift_amount
		}
	}

	negative := (dividend < 0) != (divisor < 0)
	if negative {
		if quotient == 2147483648 do return -2147483648
		return -quotient
	}
	if quotient > 2147483647 do return 2147483647
	return quotient
}
