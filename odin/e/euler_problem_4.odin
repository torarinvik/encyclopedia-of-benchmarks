package euler_problem_4

import "core:c"

MAX_DIGITS :: i64(3)
MAX_VALID_INPUT_LENGTH :: c.size_t(1)
MAX_INPUT_LENGTH :: c.size_t(2)

is_palindrome :: proc "contextless" (value: i64) -> bool {
	remaining := value
	reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return reversed == value
}

euler_problem_4 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < MAX_VALID_INPUT_LENGTH || length > MAX_INPUT_LENGTH do return -1
	if length != MAX_VALID_INPUT_LENGTH do return -1
	digit_count := input[0]
	if digit_count < 1 || digit_count > MAX_DIGITS do return -1

	lower := i64(1)
	for digit := i64(1); digit < digit_count; digit += 1 {
		lower *= 10
	}
	upper := lower * 10 - 1
	largest := i64(0)
	for left := lower; left <= upper; left += 1 {
		for right := lower; right <= upper; right += 1 {
			product := left * right
			if product > largest && is_palindrome(product) {
				largest = product
			}
		}
	}
	return largest
}
