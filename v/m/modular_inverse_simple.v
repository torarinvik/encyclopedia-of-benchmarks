module modular_inverse_simple

fn gcd_u64(left_input u64, right_input u64) u64 {
	mut left := left_input
	mut right := right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'modular_inverse_simple']
pub fn modular_inverse_simple(x_input i64, y_input i64) i64 {
	if x_input < 1 || x_input > 999 || y_input < 2 || y_input > 1000 { return -1 }
	x := u64(x_input)
	y := u64(y_input)
	if gcd_u64(x, y) != 1 { return -1 }
	mut auxiliary := u64(0)
	mut iteration := u64(0)
	for {
		auxiliary = y * iteration + 1
		iteration++
		if auxiliary % x == 0 { break }
	}
	return i64(auxiliary / x)
}
