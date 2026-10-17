package my_atoi

import "core:c"

MAX_INPUT_LENGTH :: 256
INT32_MAX_VALUE :: i64(2147483647)
INT32_MIN_MAGNITUDE :: i64(2147483648)
INVALID_RESULT :: i64(-9223372036854775807 - 1)

@(export, link_name="my_atoi")
my_atoi :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil do return 0
	if length > MAX_INPUT_LENGTH do return INVALID_RESULT
	for i := c.size_t(0); i < length; i += 1 {
		if input[i] < 0 || input[i] > 127 do return INVALID_RESULT
	}

	start := c.size_t(0)
	end := length
	for start < end && input[start] <= 32 { start += 1 }
	for end > start && input[end - 1] <= 32 { end -= 1 }
	if start == end do return 0

	negative := false
	if input[start] == 43 || input[start] == 45 {
		negative = input[start] == 45
		start += 1
	}
	limit := INT32_MAX_VALUE
	if negative do limit = INT32_MIN_MAGNITUDE
	magnitude := i64(0)
	for start < end && input[start] >= 48 && input[start] <= 57 {
		digit := input[start] - 48
		if magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10) {
			if negative do return -INT32_MIN_MAGNITUDE
			return INT32_MAX_VALUE
		}
		magnitude = magnitude * 10 + digit
		start += 1
	}
	if negative do return -magnitude
	return magnitude
}
