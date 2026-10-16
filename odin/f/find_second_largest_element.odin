package find_second_largest_element

import "core:c"

INVALID_RESULT :: i64 = -9_223_372_036_854_775_808
INT32_MIN_VALUE :: i64 = -2_147_483_648
INT32_MAX_VALUE :: i64 = 2_147_483_647

@(export)
find_second_largest_element :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 10001 do return INVALID_RESULT
	n := input[0]
	if n < 2 || n > 10000 || length != c.size_t(n + 1) do return INVALID_RESULT
	largest := INT32_MIN_VALUE
	for i := 0; i < int(n); i += 1 {
		value := input[i + 1]
		if value < INT32_MIN_VALUE || value > INT32_MAX_VALUE do return INVALID_RESULT
		if value > largest do largest = value
	}
	second := INT32_MIN_VALUE - 1
	for i := 0; i < int(n); i += 1 {
		value := input[i + 1]
		if value < largest && value > second do second = value
	}
	if second == INT32_MIN_VALUE - 1 do return INVALID_RESULT
	return second
}
