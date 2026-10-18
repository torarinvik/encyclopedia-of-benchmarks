package pollard_rho_java

import "core:c"

MIN_N :: i64(2)
MAX_N :: i64(46_340)
MAX_STEPS :: i64(4_096)

java_remainder :: proc(value, modulus: i64) -> i64 {
	if value < 0 do return -((-value) % modulus)
	return value % modulus
}

next_value :: proc(value, modulus: i64) -> i64 {
	return java_remainder(value * value - 1, modulus)
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
pollard_rho_java :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	n := input[0]
	step_limit := input[1]
	if n < MIN_N || n > MAX_N || step_limit < 1 || step_limit > MAX_STEPS do return -1

	x := i64(2)
	y := i64(2)
	for step: i64 = 0; step < step_limit; step += 1 {
		x = next_value(x, n)
		y = next_value(next_value(y, n), n)
		difference := x - y
		if difference < 0 do difference = -difference
		divisor := gcd_nonnegative(difference, n)
		if divisor == 1 do continue
		if divisor == n do return 0
		return divisor
	}
	return -2
}
