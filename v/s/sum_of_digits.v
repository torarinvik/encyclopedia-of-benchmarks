module sum_of_digits

// Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
@[export: 'sum_of_digits']
pub fn sum_of_digits(input i64) i64 {
	if input < -2147483648 || input > 2147483647 { return -1 }
	mut remaining := u64(if input < 0 { -input } else { input })
	mut total := i64(0)
	for remaining != 0 {
		total += i64(remaining % 10)
		remaining /= 10
	}
	return total
}
