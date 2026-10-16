module problem37

fn is_prime(value i64) bool {
	if value < 2 { return false }
	if value == 2 || value == 3 { return true }
	if value % 2 == 0 || value % 3 == 0 { return false }
	mut divisor := i64(5)
	for divisor <= value / divisor {
		if value % divisor == 0 || value % (divisor + 2) == 0 { return false }
		divisor += 6
	}
	return true
}

fn is_truncatable_prime(value i64) bool {
	if !is_prime(value) { return false }
	mut power := i64(10)
	for power < value {
		if !is_prime(value / power) || !is_prime(value % power) { return false }
		power *= 10
	}
	return true
}

@[export: 'problem37']
pub fn problem37(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut found := 0
	mut sum := i64(0)
	mut candidate := i64(13)
	for candidate <= 1000000 && found < 11 {
		if is_truncatable_prime(candidate) {
			sum += candidate
			found++
		}
		candidate += 2
	}
	if found == 11 { return sum }
	return -1
}
