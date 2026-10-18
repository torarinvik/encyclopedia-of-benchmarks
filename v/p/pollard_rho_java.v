const min_n = i64(2)
const max_n = i64(46_340)
const max_steps = i64(4_096)

fn java_remainder(value i64, modulus i64) i64 {
	if value < 0 { return -((-value) % modulus) }
	return value % modulus
}

fn next_value(value i64, modulus i64) i64 {
	return java_remainder(value * value - 1, modulus)
}

fn gcd_nonnegative(mut left i64, mut right i64) i64 {
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'pollard_rho_java']
pub fn pollard_rho_java(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		n := input[0]
		step_limit := input[1]
		if n < min_n || n > max_n || step_limit < 1 || step_limit > max_steps { return -1 }

		mut x := i64(2)
		mut y := i64(2)
		for _ in 0 .. int(step_limit) {
			x = next_value(x, n)
			y = next_value(next_value(y, n), n)
			difference := if x >= y { x - y } else { y - x }
			divisor := gcd_nonnegative(difference, n)
			if divisor == 1 { continue }
			if divisor == n { return 0 }
			return divisor
		}
		return -2
	}
}
