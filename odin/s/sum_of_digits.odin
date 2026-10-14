package sum_of_digits

// Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
@(export)
sum_of_digits :: proc "c" (input: i64) -> i64 {
	if input < -2147483648 || input > 2147483647 do return -1
	remaining := u64(input)
	if input < 0 {
		remaining = u64(-input)
	}
	total := i64(0)
	for remaining != 0 {
		total += i64(remaining % 10)
		remaining /= 10
	}
	return total
}
