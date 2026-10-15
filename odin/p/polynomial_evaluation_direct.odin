package polynomial_evaluation_direct

import "core:c"

INVALID_RESULT :: -9223372036854775807 - 1

integer_power :: proc(base: i64, exponent: int) -> i64 {
	result: i64 = 1
	for index := 0; index < exponent; index += 1 { result *= base }
	return result
}

// Bounded integer port of the pinned direct-power polynomial routine.
@(export)
polynomial_evaluation_direct :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 10 do return INVALID_RESULT
	count := values[0]
	x := values[1]
	if count < 0 || count > 8 || length != c.size_t(count + 2) do return INVALID_RESULT
	if x < -10 || x > 10 do return INVALID_RESULT
	for index := 0; index < int(count); index += 1 {
		coefficient := values[index + 2]
		if coefficient < -1000 || coefficient > 1000 do return INVALID_RESULT
	}
	result: i64 = 0
	for index := 0; index < int(count); index += 1 {
		result += values[index + 2] * integer_power(x, index)
	}
	return result
}
