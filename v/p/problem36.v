module problem36

const max_limit = 1_000_000

fn is_decimal_palindrome(value i64) bool {
	mut remaining := value
	mut reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return reversed == value
}

fn is_binary_palindrome(value i64) bool {
	mut remaining := value
	mut reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 2 + remaining % 2
		remaining /= 2
	}
	return reversed == value
}

@[export: 'problem36']
pub fn problem36(limit i64) i64 {
	if limit < 0 || limit > max_limit { return -1 }
	mut total := i64(0)
	for value := i64(1); value < limit; value++ {
		if is_decimal_palindrome(value) && is_binary_palindrome(value) { total += value }
	}
	return total
}
