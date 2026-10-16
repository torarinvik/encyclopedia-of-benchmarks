module problem30

fn digit_fifth_power(digit i64) i64 {
	return digit * digit * digit * digit * digit
}

@[export: 'problem30']
pub fn problem30(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut total := i64(0)
	mut number := i64(1000)
	for number < 1_000_000 {
		mut remaining := number
		mut digit_sum := i64(0)
		for remaining > 0 {
			digit_sum += digit_fifth_power(remaining % 10)
			remaining /= 10
		}
		if digit_sum == number { total += number }
		number++
	}
	return total
}
