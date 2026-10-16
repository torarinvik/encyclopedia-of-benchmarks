module problem46

const max_odd_composite = i64(99_999)

fn is_prime(number i64) bool {
	if number < 2 { return false }
	if number < 4 { return true }
	if number % 2 == 0 || number % 3 == 0 { return false }
	mut divisor := i64(5)
	for divisor <= number / divisor {
		if number % divisor == 0 || number % (divisor + 2) == 0 { return false }
		divisor += 6
	}
	return true
}

fn find_first_counterexample() i64 {
	mut candidate := i64(3)
	for candidate <= max_odd_composite {
		if !is_prime(candidate) {
			mut represented := false
			mut square := i64(0)
			for 2 * square * square <= candidate {
				if is_prime(candidate - 2 * square * square) {
					represented = true
					break
				}
				square++
			}
			if !represented { return candidate }
		}
		candidate += 2
	}
	return -1
}

@[export: 'problem46']
pub fn problem46(placeholder i64) i64 {
	if placeholder != 0 { return -1 }
	return find_first_counterexample()
}
