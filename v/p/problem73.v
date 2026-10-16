module problem73

const max_denominator_limit = 12000

fn gcd(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'problem73']
pub fn problem73(max_denominator i64) i64 {
	if max_denominator < 0 || max_denominator > max_denominator_limit { return -1 }
	mut count := i64(0)
	for denominator := i64(0); denominator <= max_denominator; denominator++ {
		mut numerator_start := denominator / 3 + 1
		mut numerator_step := i64(1)
		if denominator % 2 == 0 {
			numerator_start += 1 - numerator_start % 2
			numerator_step = 2
		}
		numerator_end := (denominator + 1) / 2
		mut numerator := numerator_start
		for numerator < numerator_end {
			if gcd(numerator, denominator) == 1 { count++ }
			numerator += numerator_step
		}
	}
	return count
}
