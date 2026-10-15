package spy_number

// Return whether a positive integer's decimal digit sum equals its product.
@(export)
spy_number :: proc "c" (input: i64) -> i64 {
	if input <= 0 do return 0
	number := input
	digit_sum := i64(0)
	digit_product := i64(1)
	for number > 0 {
		digit := number % 10
		digit_sum += digit
		digit_product *= digit
		number /= 10
	}
	return i64(digit_sum == digit_product)
}
