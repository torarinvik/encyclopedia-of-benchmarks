package missing_number_in_range

import "core:c"

MAX_VALUES :: 1024
INVALID_RESULT :: i64(-2_147_483_649)

encode_i32 :: proc "contextless" (value: i64) -> u64 {
	if value < 0 do return u64(value + 4_294_967_296)
	return u64(value)
}

@(export)
missing_number_in_range :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_VALUES) do return INVALID_RESULT
	low := values[0]
	high := low
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return INVALID_RESULT
		low = min(low, value)
		high = max(high, value)
	}
	if high - low != i64(length) do return INVALID_RESULT
	seen: [MAX_VALUES + 1]bool
	actual := u64(0)
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		slot := int(value - low)
		if seen[slot] do return INVALID_RESULT
		seen[slot] = true
		actual = actual ~ encode_i32(value)
	}
	expected := u64(0)
	for value := low; value <= high; value += 1 {
		expected = expected ~ encode_i32(value)
	}
	result := expected ~ actual
	if result <= 2_147_483_647 do return i64(result)
	return i64(result) - 4_294_967_296
}
