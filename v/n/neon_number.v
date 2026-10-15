module neon_number

@[export: 'neon_number']
pub fn neon_number(number i64) i64 {
	if number < 0 { return 0 }
	if number > 3_000_000_000 { return -1 }
	mut square := number * number
	mut digit_sum := i64(0)
	for square > 0 {
		digit_sum += square % 10
		square /= 10
	}
	if digit_sum == number { return 1 }
	return 0
}
