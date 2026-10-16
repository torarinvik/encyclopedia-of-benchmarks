package double_linear_search_recursion

import "core:c"

MAX_ITEMS :: 1024
INVALID_RESULT :: i64(-2)

search_range :: proc(values: [^]i64, key, left, right: i64, offset: int) -> i64 {
	if left > right do return -1
	if values[offset + int(left)] == key do return left
	if values[offset + int(right)] == key do return right
	return search_range(values, key, left + 1, right - 1, offset)
}

@(export)
double_linear_search_recursion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 1026 do return INVALID_RESULT
	count, key := input[0], input[1]
	if count < 0 || count > MAX_ITEMS || key < -2147483648 || key > 2147483647 ||
		length != c.size_t(2 + count) do return INVALID_RESULT
	for index := i64(0); index < count; index += 1 {
		value := input[2 + index]
		if value < -2147483648 || value > 2147483647 do return INVALID_RESULT
	}
	return search_range(input, key, 0, count - 1, 2)
}
