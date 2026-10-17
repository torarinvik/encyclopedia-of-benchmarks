const min_n = i64(2)
const max_n = i64(111_155)

fn next_value(n i64, x i64) i64 {
	return (x * x + 1) % n
}

fn gcd_nonnegative(mut left i64, mut right i64) i64 {
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'pollard']
pub fn pollard(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	unsafe {
		n := input[0]
		if n < min_n || n > max_n { return -1 }

		mut x := i64(2)
		mut y := i64(2)
		mut divisor := i64(1)
		for divisor == 1 {
			x = next_value(n, x)
			y = next_value(n, next_value(n, y))
			mut difference := x - y
			if difference < 0 { difference = -difference }
			divisor = gcd_nonnegative(difference, n)
		}
		if divisor == n { return 0 }
		return divisor
	}
}
