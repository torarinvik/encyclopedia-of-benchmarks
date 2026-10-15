module recursive_digit_sum

fn digit_sum(number i64) i64 {
	mut remaining := number
	mut sum := i64(0)
	for remaining != 0 {
		sum += remaining % 10
		remaining /= 10
	}
	return sum
}

@[export: 'recursive_digit_sum']
pub fn recursive_digit_sum(number i64, repetitions i64) i64 {
	if number < 0 || repetitions < 0 || repetitions > 1_000_000 { return -1 }
	mut total := digit_sum(number) * repetitions
	for total >= 10 { total = digit_sum(total) }
	return total
}
