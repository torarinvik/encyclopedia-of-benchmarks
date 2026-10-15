module strong_number

@[export: 'strong_number']
pub fn strong_number(number i64) i64 {
	if number < -2147483648 || number > 2147483647 { return -1 }
	if number < 0 { return 0 }
	mut remaining := number
	mut sum := i64(0)
	if remaining == 0 { sum = 1 }
	for remaining > 0 {
		digit := remaining % 10
		mut factorial := i64(1)
		mut factor := i64(2)
		for factor <= digit { factorial *= factor; factor++ }
		sum += factorial
		remaining /= 10
	}
	if sum == number { return 1 }
	return 0
}
