module squfof_semiprime_factor

const max_number = i64(1_000_000_000_000)
const max_steps = i64(256)

fn sq_isqrt(value i64, upper i64) i64 {
	mut low := i64(0)
	mut high := upper + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

fn sq_gcd(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn sq_reverse(number i64, discriminant i64, a i64, p i64, q i64, cap i64) i64 {
	root := sq_isqrt(q, 1_414_214)
	if root * root != q { return 0 }
	quotient := (a - p) / root
	mut r := quotient * root + p
	mut previous_s := root
	mut s := (discriminant - r * r) / root
	mut step := i64(0)
	for step < cap {
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
		previous_s = s
		s = next_s
		r = next_r
		step++
	}
	return 0
}

@[export: 'squfof_semiprime_factor']
pub fn squfof_semiprime_factor(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	unsafe {
		number, forward_cap, reverse_cap := input[0], input[1], input[2]
		if number < 3 || number > max_number || number % 2 == 0 || forward_cap < 0 || forward_cap > max_steps || reverse_cap < 0 || reverse_cap > max_steps { return -1 }
		exact_root := sq_isqrt(number, 1_000_000)
		if exact_root * exact_root == number { return exact_root }
		discriminant := number
		if number % 4 == 1 { discriminant = 2 * number }
		a := sq_isqrt(discriminant, 1_414_214)
		mut previous_q := i64(1)
		mut q := discriminant - a * a
		mut p := a
		mut index := i64(1)
		mut step := i64(0)
		for step < forward_cap {
			quotient := (a + p) / q
			next_p := quotient * q - p
			next_q := previous_q + quotient * (p - next_p)
			previous_q = q
			q = next_q
			p = next_p
			index++
			if index % 2 == 0 {
				factor := sq_reverse(number, discriminant, a, p, q, reverse_cap)
				if factor != 0 { return factor }
			}
			step++
		}
		return 0
	}
}
