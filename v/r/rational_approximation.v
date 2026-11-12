module rational_approximation

const max_component = i64(1_000_000_000)

struct Bounds {
	lower_num i64
	lower_den i64
	upper_num i64
	upper_den i64
}

fn gcd_positive(left_input i64, right_input i64) i64 {
	mut left := left_input
	mut right := right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn bounded_neighbors(limit i64, x i64, y i64) Bounds {
	divisor := gcd_positive(x, y)
	reduced_x := x / divisor
	reduced_y := y / divisor
	if reduced_x <= limit && reduced_y <= limit {
		return Bounds{reduced_x, reduced_y, reduced_x, reduced_y}
	}
	mut a := i64(0)
	mut b := i64(1)
	mut c := i64(1)
	mut d := i64(0)
	for {
		middle_num := a + c
		middle_den := b + d
		if middle_num > limit || middle_den > limit { break }
		target_side := middle_num * y
		middle_side := middle_den * x
		if target_side == middle_side {
			return Bounds{middle_num, middle_den, middle_num, middle_den}
		}
		if target_side < middle_side {
			lower_gap := b * x - a * y
			upper_gap := c * y - d * x
			mut step := lower_gap / upper_gap
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
			mut step := upper_gap / lower_gap
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

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'rational_approximation']
pub fn rational_approximation(values &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	if unsafe { values == nil } || length != 3 { return -1 }
	unsafe {
		limit, x, y := values[0], values[1], values[2]
		if limit < 1 || limit > max_component || x < 1 || x > max_component ||
			y < 1 || y > max_component { return -1 }
		if output == nil || output_capacity < 32 { return -2 }
		bounds := bounded_neighbors(limit, x, y)
		store_i64_le(mut output, 0, bounds.lower_num)
		store_i64_le(mut output, 8, bounds.lower_den)
		store_i64_le(mut output, 16, bounds.upper_num)
		store_i64_le(mut output, 24, bounds.upper_den)
		return 32
	}
}
