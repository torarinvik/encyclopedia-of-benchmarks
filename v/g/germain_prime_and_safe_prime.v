module germain_prime_and_safe_prime

const max_number = i64(1_000_000)

fn is_prime(value i64) bool {
	if value == 2 { return true }
	if value < 2 || value % 2 == 0 { return false }
	mut divisor := i64(3)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
	divisor += 2
	}
	return true
}

@[export: 'germain_prime_and_safe_prime']
pub fn germain_prime_and_safe_prime(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	if unsafe { values == nil } { return -1 }
	number := unsafe { values[0] }
	selector := unsafe { values[1] }
	if number < 1 || number > max_number || selector < 0 || selector > 1 { return -1 }
	if selector == 0 {
		if is_prime(number) && is_prime(2 * number + 1) { return 1 }
		return 0
	}
	if (number - 1) % 2 == 0 && is_prime(number) && is_prime((number - 1) / 2) { return 1 }
	return 0
}
