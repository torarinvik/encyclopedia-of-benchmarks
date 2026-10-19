module fib2

fn fib2_value(n i64) i64 {
	if n < 2 { return 1 }
	return fib2_value(n - 2) + fib2_value(n - 1)
}

@[export: 'fib2']
pub fn fib2(n i64) i64 {
	if n < 0 || n > 30 { return -1 }
	return fib2_value(n)
}
