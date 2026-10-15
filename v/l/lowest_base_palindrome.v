module lowest_base_palindrome

// Smallest base in which a nonnegative integer is palindromic.
fn is_palindromic_in_base(number i64, base i64) bool {
	if number <= 1 { return true }
	if number % base == 0 { return false }
	mut remaining := number
	mut reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * base + remaining % base
		remaining /= base
	}
	return reversed == number
}

@[export: 'lowest_base_palindrome']
pub fn lowest_base_palindrome(number i64) i64 {
	if number < 0 || number > 64 { return -1 }
	mut base := i64(2)
	for !is_palindromic_in_base(number, base) { base++ }
	return base
}
