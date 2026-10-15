module disarium_number

@[export: 'disarium_number']
pub fn disarium_number(number i64) i64 {
	if number < 1 || number > 99_999_999 { return -1 }
	mut digits := i64(0)
	mut count_value := number
	for count_value > 0 {
		digits++
		count_value /= 10
	}
	mut position := digits
	mut remaining := number
	mut sum := i64(0)
	for remaining > 0 {
		digit := remaining % 10
		mut power := i64(1)
		for mut exponent := i64(0); exponent < position; exponent++ { power *= digit }
		sum += power
		position--
		remaining /= 10
	}
	if sum == number { return 1 }
	return 0
}
