module reverse_factorial_recursive

fn reverse_factorial_recursive_impl(value i64, divisor i64) i64 {
	if value == 1 {
		if divisor == 1 { return 1 }
		return divisor - 1
	}
	if value % divisor != 0 { return -1 }
	return reverse_factorial_recursive_impl(value / divisor, divisor + 1)
}

@[export: 'reverse_factorial_recursive']
pub fn reverse_factorial_recursive(value i64) i64 {
	if value < 1 { return -1 }
	return reverse_factorial_recursive_impl(value, 1)
}
