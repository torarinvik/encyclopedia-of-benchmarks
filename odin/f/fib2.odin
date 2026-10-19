package fib2

fib2_value :: proc "contextless" (n: i64) -> i64 {
	if n < 2 do return 1
	return fib2_value(n - 2) + fib2_value(n - 1)
}

@(export)
fib2 :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 30 do return -1
	return fib2_value(n)
}
