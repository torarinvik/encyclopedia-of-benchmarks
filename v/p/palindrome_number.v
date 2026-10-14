module palindrome_number

// Reverse half the digits to avoid overflow.
@[export: 'palindrome_number']
pub fn palindrome_number(value i64) i64 {
	if value < 0 || value > 2147483647 { return -1 }
	if value != 0 && value % 10 == 0 { return 0 }
	mut remaining := value
	mut reversed_half := i64(0)
	for remaining > reversed_half {
		reversed_half = reversed_half * 10 + remaining % 10
		remaining /= 10
	}
	if remaining == reversed_half || remaining == reversed_half / 10 { return 1 }
	return 0
}
