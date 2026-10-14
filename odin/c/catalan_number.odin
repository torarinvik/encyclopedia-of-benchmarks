package catalan_number

gcd_i64 :: proc "contextless" (left_value, right_value: i64) -> i64 {
	left, right := left_value, right_value
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

// Return the exact zero-based Catalan number through the signed 64-bit range.
@(export)
catalan_number :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 35 do return -1
	value := i64(1)
	for index := i64(1); index <= n; index += 1 {
		numerator := 4 * index - 2
		denominator := index + 1
		common := gcd_i64(numerator, denominator)
		numerator /= common
		denominator /= common
		value = (value / denominator) * numerator
	}
	return value
}
