module spy_number

// Return whether a positive integer's decimal digit sum equals its product.
@[export: 'spy_number']
pub fn spy_number(input i64) i64 {
	if input <= 0 { return 0 }
	mut number := input
	mut digit_sum := i64(0)
	mut digit_product := i64(1)
	for number > 0 {
		digit := number % 10
		digit_sum += digit
		digit_product *= digit
		number /= 10
	}
	return if digit_sum == digit_product { 1 } else { 0 }
}
