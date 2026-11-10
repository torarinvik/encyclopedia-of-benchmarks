package catalan_number

// Return the exact zero-based Catalan number through the signed 64-bit range.
@(export)
catalan_number :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 35 do return -1
	value := i64(1)
	for index := i64(1); index <= n; index += 1 {
		numerator := 4 * index - 2
		denominator := index + 1
		common := (i64(3) if denominator % 3 == 0 else i64(1)) * (i64(2) if denominator % 2 == 0 else i64(1))
		numerator /= common
		denominator /= common
		value = (value / denominator) * numerator
	}
	return value
}
