module tribonacci

// Portable zero-based Tribonacci recurrence for the shared i64 contract.
@[export: 'tribonacci']
pub fn tribonacci(n i64) i64 {
	if n < 0 || n > 73 { return -1 }
	if n == 0 { return 0 }
	if n <= 2 { return 1 }
	mut previous_three := i64(0)
	mut previous_two := i64(1)
	mut previous_one := i64(1)
	for index := i64(3); index <= n; index++ {
		next := previous_three + previous_two + previous_one
		previous_three = previous_two
		previous_two = previous_one
		previous_one = next
	}
	return previous_one
}
