package uniform_numbers

// Count positive repdigits up to the input using the pinned prefix formula.
@(export)
uniform_numbers :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 999999999 do return -1
	remaining := value
	first_digit: i64 = 0
	digits: i64 = 0
	for {
		first_digit = remaining % 10
		remaining /= 10
		digits += 1
		if remaining == 0 do break
	}
	repeated: i64 = 0
	for index := i64(0); index < digits; index += 1 {
		repeated = repeated * 10 + first_digit
	}
	count := (digits - 1) * 9
	if repeated <= value do return count + first_digit
	return count + first_digit - 1
}
