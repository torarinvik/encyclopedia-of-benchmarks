package pollards_rho_factorizing

MIN_N :: i64(2)
MAX_N :: i64(46_340)

next_value :: proc(n, x: i64) -> i64 {
	return (x * x + 1) % n
}

gcd_nonnegative :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@(export)
pollards_rho_factorizing :: proc "c" (n: i64) -> i64 {
	if n < MIN_N || n > MAX_N do return -1
	x := i64(2)
	y := i64(2)
	divisor := i64(1)
	for divisor == 1 {
		x = next_value(n, x)
		y = next_value(n, next_value(n, y))
		difference := x - y
		if difference < 0 do difference = -difference
		divisor = gcd_nonnegative(difference, n)
	}
	return divisor
}
