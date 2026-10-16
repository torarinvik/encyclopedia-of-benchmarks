package modular_inverse_simple

gcd_u64 :: proc(left_input, right_input: u64) -> u64 {
	left, right := left_input, right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@(export)
modular_inverse_simple :: proc "c" (x_input, y_input: i64) -> i64 {
	if x_input < 1 || x_input > 999 || y_input < 2 || y_input > 1000 do return -1
	x, y := u64(x_input), u64(y_input)
	if gcd_u64(x, y) != 1 do return -1

	auxiliary: u64 = 0
	iteration: u64 = 0
	for {
		auxiliary = y * iteration + 1
		iteration += 1
		if auxiliary % x == 0 do break
	}
	return i64(auxiliary / x)
}
