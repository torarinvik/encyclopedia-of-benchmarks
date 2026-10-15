package almost_palindrome_checker

import "core:c"

MAX_LENGTH :: 100_000

is_palindrome_range :: proc "contextless" (text: [^]i64, left_start, right_start: c.size_t) -> bool {
	left := left_start
	right := right_start
	for left < right {
		if text[left] != text[right - 1] do return false
		left += 1
		right -= 1
	}
	return true
}

@(export)
almost_palindrome_checker :: proc "c" (text: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if text[index] < 97 || text[index] > 122 do return -1
	}
	left := c.size_t(0)
	right := length
	for left < right {
		if text[left] != text[right - 1] {
			if is_palindrome_range(text, left + 1, right) || is_palindrome_range(text, left, right - 1) do return 1
			return 0
		}
		left += 1
		right -= 1
	}
	return 1
}
