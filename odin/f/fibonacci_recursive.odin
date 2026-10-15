package fibonacci_recursive

fibonacci_value :: proc "contextless" (n: i64) -> i64 {
	if n < 2 do return n
	return fibonacci_value(n - 1) + fibonacci_value(n - 2)
}

@(export)
fibonacci_recursive :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 30 do return -1
	return fibonacci_value(n)
}
