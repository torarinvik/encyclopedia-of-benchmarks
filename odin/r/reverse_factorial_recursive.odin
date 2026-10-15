package reverse_factorial_recursive

reverse_factorial_recursive_impl :: proc(value, divisor: i64) -> i64 {
	if value == 1 {
		if divisor == 1 do return 1
		return divisor - 1
	}
	if value % divisor != 0 do return -1
	return reverse_factorial_recursive_impl(value / divisor, divisor + 1)
}

@(export)
reverse_factorial_recursive :: proc "c" (value: i64) -> i64 {
	if value < 1 do return -1
	return reverse_factorial_recursive_impl(value, 1)
}
