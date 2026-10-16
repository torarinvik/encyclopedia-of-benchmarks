package second_min_max

import "core:c"

INVALID_RESULT :: i64 = -9_223_372_036_854_775_808
INT32_MIN_VALUE :: i64 = -2_147_483_648
INT32_MAX_VALUE :: i64 = 2_147_483_647
MAX_INPUT_LENGTH :: c.size_t = 259

@(export)
second_min_max :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	operation, raw_count := input[0], input[1]
	if (operation != 0 && operation != 1) || raw_count < 2 || raw_count > 256 do return INVALID_RESULT
	count := int(raw_count)
	if length != c.size_t(count + 2) do return INVALID_RESULT
	initial := INT32_MIN_VALUE
	if operation == 0 do initial = INT32_MAX_VALUE
	best, second := initial, initial
	for index := 0; index < count; index += 1 {
		value := input[index + 2]
		if value < INT32_MIN_VALUE || value > INT32_MAX_VALUE do return INVALID_RESULT
		better := operation == 0 && value < best || operation == 1 && value > best
		if better {
			second = best
			best = value
		} else {
			improves_second := operation == 0 && value < second || operation == 1 && value > second
			if improves_second && value != best do second = value
		}
	}
	if second == initial do return INVALID_RESULT
	return second
}
