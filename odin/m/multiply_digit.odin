package multiply_digit

import "core:c"

INVALID_RESULT :: i64(-9223372036854775807) - 1

// Multiply two bounded signed operands; the bounds guarantee an i64 result.
@(export)
multiply_digit :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return INVALID_RESULT
	first := values[0]
	second := values[1]
	if first < -1000000000 || first > 1000000000 ||
		second < -1000000000 || second > 1000000000 {
		return INVALID_RESULT
	}
	return first * second
}
