package rational_approximation

import "core:c"

MAX_COMPONENT :: i64(1_000_000_000)

Bounds :: struct {
	lower_num: i64,
	lower_den: i64,
	upper_num: i64,
	upper_den: i64,
}

gcd_positive :: proc "contextless" (left_input, right_input: i64) -> i64 {
	left, right := left_input, right_input
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

bounded_neighbors :: proc "contextless" (limit, x, y: i64) -> Bounds {
	divisor := gcd_positive(x, y)
	reduced_x, reduced_y := x / divisor, y / divisor
	if reduced_x <= limit && reduced_y <= limit {
		return Bounds{reduced_x, reduced_y, reduced_x, reduced_y}
	}
	a, b := i64(0), i64(1)
	c, d := i64(1), i64(0)
	for true {
		middle_num, middle_den := a + c, b + d
		if middle_num > limit || middle_den > limit do break
		target_side := middle_num * y
		middle_side := middle_den * x
		if target_side == middle_side {
			return Bounds{middle_num, middle_den, middle_num, middle_den}
		}
		if target_side < middle_side {
			lower_gap := b * x - a * y
			upper_gap := c * y - d * x
			step := lower_gap / upper_gap
			numerator_cap := (limit - a) / c
			if step > numerator_cap { step = numerator_cap }
			if d > 0 {
				denominator_cap := (limit - b) / d
				if step > denominator_cap { step = denominator_cap }
			}
			a += step * c
			b += step * d
		} else {
			upper_gap := c * y - d * x
			lower_gap := b * x - a * y
			step := upper_gap / lower_gap
			if a > 0 {
				numerator_cap := (limit - c) / a
				if step > numerator_cap { step = numerator_cap }
			}
			denominator_cap := (limit - d) / b
			if step > denominator_cap { step = denominator_cap }
			c += step * a
			d += step * b
		}
	}
	return Bounds{a, b, c, d}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
rational_approximation :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	limit, x, y := values[0], values[1], values[2]
	if limit < 1 || limit > MAX_COMPONENT || x < 1 || x > MAX_COMPONENT ||
		y < 1 || y > MAX_COMPONENT do return -1
	if output == nil || output_capacity < 32 do return -2

	bounds := bounded_neighbors(limit, x, y)
	store_i64_le(output, 0, bounds.lower_num)
	store_i64_le(output, 8, bounds.lower_den)
	store_i64_le(output, 16, bounds.upper_num)
	store_i64_le(output, 24, bounds.upper_den)
	return 32
}
