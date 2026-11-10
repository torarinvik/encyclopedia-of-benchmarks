package sum_of_digits

// Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
@(export)
sum_of_digits :: proc "c" (input: i64) -> i64 {
	if input < -2147483648 || input > 2147483647 do return -1
	magnitude := u32(input)
	if input < 0 {
		magnitude = u32(-input)
	}
	remaining := magnitude
	total := u32(0)
	for remaining >= 10 {
		next_quotient := remaining / 10
		remaining /= 100
		total += next_quotient + remaining
	}
	return i64(magnitude - 9 * total)
}
