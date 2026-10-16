package twos_complement_of_binary

@(export)
twos_complement_of_binary :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 1111111111111111 do return -1
	if value == 0 do return 0

	remaining := value
	for remaining > 0 {
		digit := remaining % 10
		if digit != 0 && digit != 1 do return -1
		remaining /= 10
	}

	remaining = value
	reversed := i64(0)
	width := i64(0)
	for remaining > 0 && remaining % 10 == 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
		width += 1
	}
	if remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
		width += 1
	}
	for remaining > 0 {
		digit := remaining % 10
		if digit == 1 do reversed = reversed * 10
		else do reversed = reversed * 10 + 1
		remaining /= 10
		width += 1
	}

	result := i64(0)
	for width > 0 {
		result = result * 10 + reversed % 10
		reversed /= 10
		width -= 1
	}
	return result
}
