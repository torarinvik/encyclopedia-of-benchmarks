module sum_of_odd_numbers

@[export: 'sum_of_odd_numbers']
pub fn sum_of_odd_numbers(n i64) i64 {
	if n < 0 || n > 46340 { return -1 }
	return n * n
}
