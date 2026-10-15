package greatest_common_factor

import "core:c"

MAX_ITEMS :: 256
MAX_SAFE_INTEGER :: i64(9007199254740991)
INVALID_RESULT :: i64(-9223372036854775807 - 1)

gcd_nonnegative :: proc "contextless" (left_value, right_value: i64) -> i64 {
	left, right := left_value, right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@(export)
greatest_common_factor :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_ITEMS + 1 do return INVALID_RESULT
	count := values[0]
	if count < 1 || count > MAX_ITEMS || length != c.size_t(count + 1) do return INVALID_RESULT
	result := values[1]
	if result < 0 || result > MAX_SAFE_INTEGER do return INVALID_RESULT
	for index := c.size_t(2); index < length; index += 1 {
		value := values[index]
		if value < 0 || value > MAX_SAFE_INTEGER do return INVALID_RESULT
		result = gcd_nonnegative(result, value)
	}
	return result
}
