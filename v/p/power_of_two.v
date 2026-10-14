module power_of_two

// Return 1 when n is a positive power of two, otherwise 0.
@[export: 'power_of_two']
pub fn power_of_two(n i64) i64 {
	if n <= 0 { return 0 }
	if (n & (n - 1)) == 0 { return 1 }
	return 0
}
