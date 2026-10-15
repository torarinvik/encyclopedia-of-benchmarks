package c_atoi_str_to_integer

import "core:c"

MAX_INPUT_LENGTH :: 4096
INT32_MAX_VALUE :: i64(2147483647)
INT32_MIN_MAGNITUDE :: i64(2147483648)

@(export)
c_atoi_str_to_integer :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_INPUT_LENGTH || (length != 0 && input == nil) do return -2
	for position := c.size_t(0); position < length; position += 1 {
		if input[position] < 0 || input[position] > 127 do return -2
	}
	index := c.size_t(0)
	for index < length && input[index] != 0 && ((input[index] >= 9 && input[index] <= 13) || input[index] == 32) { index += 1 }
	negative := false
	if index < length && input[index] != 0 && (input[index] == 43 || input[index] == 45) {
		negative = input[index] == 45
		index += 1
	}
	limit := INT32_MAX_VALUE
	if negative do limit = INT32_MIN_MAGNITUDE
	magnitude := i64(0)
	for index < length && input[index] != 0 && input[index] >= 48 && input[index] <= 57 {
		digit := input[index] - 48
		if magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10) {
			if negative do return -INT32_MIN_MAGNITUDE
			return INT32_MAX_VALUE
		}
		magnitude = magnitude * 10 + digit
		index += 1
	}
	if negative do return -magnitude
	return magnitude
}
