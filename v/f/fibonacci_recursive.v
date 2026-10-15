module fibonacci_recursive

fn fibonacci_value(n i64) i64 {
	if n < 2 { return n }
	return fibonacci_value(n - 1) + fibonacci_value(n - 2)
}

@[export: 'fibonacci_recursive']
pub fn fibonacci_recursive(n i64) i64 {
	if n < 0 || n > 30 { return -1 }
	return fibonacci_value(n)
}
