module problem34

const digit_factorials = [10]i64{1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880}

@[export: 'problem34']
pub fn problem34(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut total := i64(0)
	mut number := i64(3)
	for number <= 2_540_160 {
		mut remaining := number
		mut digit_sum := i64(0)
		for remaining > 0 {
			digit_sum += digit_factorials[int(remaining % 10)]
			remaining /= 10
		}
		if digit_sum == number { total += number }
		number++
	}
	return total
}
