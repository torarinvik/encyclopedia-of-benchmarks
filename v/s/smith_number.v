module smith_number

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

fn digit_sum(value_arg i64) i64 {
	mut value := value_arg
	mut sum := i64(0)
	for value != 0 {
		sum += value % 10
		value /= 10
	}
	return sum
}

fn prime_factor_digit_sum(value i64) i64 {
	mut sum := i64(0)
	mut remainder := value
	mut factor := i64(2)
	for factor <= value / factor {
		for remainder % factor == 0 {
			sum += digit_sum(factor)
			remainder /= factor
		}
		factor++
	}
	if remainder > 1 { sum += digit_sum(remainder) }
	return sum
}

@[export: 'smith_number']
pub fn smith_number(value i64) i64 {
	if value < 1 || value > 2147395599 { return -1 }
	if is_prime(value) { return 0 }
	return if digit_sum(value) == prime_factor_digit_sum(value) { 1 } else { 0 }
}
