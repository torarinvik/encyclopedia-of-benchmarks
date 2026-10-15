package ackermann

ackermann_value :: proc "contextless" (m, n: i64) -> i64 {
	if m == 0 do return n + 1
	if n == 0 do return ackermann_value(m - 1, 1)
	return ackermann_value(m - 1, ackermann_value(m, n - 1))
}

@(export)
ackermann :: proc "c" (m, n: i64) -> i64 {
	if m < 0 || m > 3 || n < 0 || n > 5 do return -1
	return ackermann_value(m, n)
}
