package max_value

@(export)
max_value :: proc "c" (a, b: i64) -> i64 {
	if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 do return -1
	if a >= b do return a
	return b
}
