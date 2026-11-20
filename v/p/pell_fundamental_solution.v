module pell_fundamental_solution

fn fundamental_solution(discriminant i64) (i64, i64) {
	mut root := i64(0)
	for (root + 1) * (root + 1) <= discriminant { root++ }

	mut previous_numerator := i64(0)
	mut numerator := i64(1)
	mut previous_denominator := i64(1)
	mut denominator := i64(0)
	mut m := i64(0)
	mut d := i64(1)
	mut a := root
	for {
		next_numerator := a * numerator + previous_numerator
		next_denominator := a * denominator + previous_denominator
		if next_numerator * next_numerator - discriminant * next_denominator * next_denominator == 1 {
			return next_numerator, next_denominator
		}

		previous_numerator = numerator
		numerator = next_numerator
		previous_denominator = denominator
		denominator = next_denominator

		m = d * a - m
		d = (discriminant - m * m) / d
		a = (root + m) / d
	}
	return 0, 0
}

@[export: 'pell_fundamental_solution']
pub fn pell_fundamental_solution(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		discriminant := input[0]
		if discriminant < 2 || discriminant > 31 { return -1 }

		mut root := i64(0)
		for (root + 1) * (root + 1) <= discriminant { root++ }
		if root * root == discriminant { return -1 }

		x, y := fundamental_solution(discriminant)
		return (x << 32) | y
	}
}
