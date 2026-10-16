module problem41

const max_digits = 9

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

fn search(digits int, depth int, used u16, value i64) i64 {
	if depth == digits { return if is_prime(value) { value } else { i64(0) } }
	mut best := i64(0)
	for digit in 1 .. digits + 1 {
		bit := u16(1 << digit)
		if used & bit != 0 { continue }
		candidate := search(digits, depth + 1, used | bit, value * 10 + digit)
		if candidate > best { best = candidate }
	}
	return best
}

@[export: 'problem41']
pub fn problem41(digits i64) i64 {
	if digits < 1 || digits > max_digits { return -1 }
	return search(int(digits), 0, 0, 0)
}
