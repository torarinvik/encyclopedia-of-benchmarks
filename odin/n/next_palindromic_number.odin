package next_palindromic_number

import "core:c"

MAX_INPUT :: i64(9999999999999999)

next_for :: proc "contextless" (number: i64) -> i64 {
	digits: [17]u8
	remaining := number
	count := 0
	for {
		digits[count] = u8(remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for left := 0; left < count / 2; left += 1 {
		right := count - 1 - left
		swap := digits[left]
		digits[left] = digits[right]
		digits[right] = swap
	}
	for left := 0; left < count / 2; left += 1 {
		digits[count - 1 - left] = digits[left]
	}
	candidate := i64(0)
	for i := 0; i < count; i += 1 { candidate = candidate * 10 + i64(digits[i]) }
	if candidate > number do return candidate

	position := (count + 1) / 2
	for position > 0 && digits[position - 1] == 9 {
		digits[position - 1] = 0
		position -= 1
	}
	if position == 0 {
		power := i64(1)
		for i := 0; i < count; i += 1 { power *= 10 }
		return power + 1
	}
	digits[position - 1] += 1
	for left := 0; left < count / 2; left += 1 {
		digits[count - 1 - left] = digits[left]
	}
	candidate = 0
	for i := 0; i < count; i += 1 { candidate = candidate * 10 + i64(digits[i]) }
	return candidate
}

@(export)
next_palindromic_number :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != c.size_t(1) do return -1
	number := values[0]
	if number < 0 || number > MAX_INPUT do return -1
	return next_for(number)
}
