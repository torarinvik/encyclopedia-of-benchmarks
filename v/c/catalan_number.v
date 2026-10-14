module catalan_number

fn gcd_i64(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

// Return the exact zero-based Catalan number through the signed 64-bit range.
@[export: 'catalan_number']
pub fn catalan_number(n i64) i64 {
	if n < 0 || n > 35 { return -1 }
	mut value := i64(1)
	mut index := i64(1)
	for index <= n {
		mut numerator := 4 * index - 2
		mut denominator := index + 1
		common := gcd_i64(numerator, denominator)
		numerator /= common
		denominator /= common
		value = (value / denominator) * numerator
		index++
	}
	return value
}
