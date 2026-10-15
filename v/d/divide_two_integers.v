module divide_two_integers

// Truncate signed 32-bit division toward zero using doubled divisor chunks.
@[export: 'divide_two_integers']
pub fn divide_two_integers(values &i64, length usize) i64 {
	if length != 2 { return i64(-2147483648) - 1 }
	dividend := unsafe { values[0] }
	divisor := unsafe { values[1] }
	if dividend < -2147483648 || dividend > 2147483647 ||
		divisor < -2147483648 || divisor > 2147483647 || divisor == 0 { return i64(-2147483648) - 1 }

	mut remaining := dividend
	if remaining < 0 { remaining = -remaining }
	divisor_magnitude := if divisor < 0 { -divisor } else { divisor }
	mut quotient := i64(0)
	for step in 0 .. 32 {
		shift := 31 - step
		if divisor_magnitude <= (remaining >> shift) {
			remaining -= divisor_magnitude << shift
			quotient += i64(1) << shift
		}
	}

	negative := (dividend < 0) != (divisor < 0)
	if negative {
		if quotient == 2147483648 { return -2147483648 }
		return -quotient
	}
	if quotient > 2147483647 { return 2147483647 }
	return quotient
}
