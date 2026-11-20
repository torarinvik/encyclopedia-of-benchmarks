package squfof_semiprime_factor

import "core:c"

sq_isqrt :: proc(value, upper: i64) -> i64 {
	low: i64 = 0
	high := upper + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

sq_gcd :: proc(left_value, right_value: i64) -> i64 {
	left, right := left_value, right_value
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

sq_reverse :: proc(number, discriminant, a, p, q, cap: i64) -> i64 {
	root := sq_isqrt(q, 1_414_214)
	if root * root != q do return 0
	quotient := (a - p) / root
	r := quotient * root + p
	previous_s := root
	s := (discriminant - r * r) / root
	for step: i64 = 0; step < cap; step += 1 {
		next_quotient := (a + r) / s
		next_r := next_quotient * s - r
		if next_r == r {
			factor := sq_gcd(number, r)
			if factor > 1 && factor < number {
				other := number / factor
				if factor < other { return factor }
				return other
			}
			return 0
		}
		next_s := previous_s + next_quotient * (r - next_r)
		previous_s, s, r = s, next_s, next_r
	}
	return 0
}

@(export)
squfof_semiprime_factor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	number, forward_cap, reverse_cap := input[0], input[1], input[2]
	if number < 3 || number > 1_000_000_000_000 || number % 2 == 0
		|| forward_cap < 0 || forward_cap > 256 || reverse_cap < 0 || reverse_cap > 256 do return -1
	exact_root := sq_isqrt(number, 1_000_000)
	if exact_root * exact_root == number do return exact_root
	discriminant := number
	if number % 4 == 1 { discriminant = 2 * number }
	a := sq_isqrt(discriminant, 1_414_214)
	previous_q: i64 = 1
	q := discriminant - a * a
	p := a
	index: i64 = 1
	for step: i64 = 0; step < forward_cap; step += 1 {
		quotient := (a + p) / q
		next_p := quotient * q - p
		next_q := previous_q + quotient * (p - next_p)
		previous_q, q, p = q, next_q, next_p
		index += 1
		if index % 2 == 0 {
			factor := sq_reverse(number, discriminant, a, p, q, reverse_cap)
			if factor != 0 do return factor
		}
	}
	return 0
}
