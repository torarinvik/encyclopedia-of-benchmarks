package volume

import "core:c"

MAX_DIMENSION :: i64(1000)
INVALID_RESULT :: i64(-1)

@(export)
volume :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 4 do return INVALID_RESULT
	operation, a, b, c_value := input[0], input[1], input[2], input[3]
	if a < 0 || a > MAX_DIMENSION || b < 0 || b > MAX_DIMENSION || c_value < 0 || c_value > MAX_DIMENSION do return INVALID_RESULT
	if operation == 0 {
		if b != 0 || c_value != 0 do return INVALID_RESULT
		return a * a * a
	}
	if operation == 1 do return a * b * c_value
	if operation == 2 {
		product := a * b * c_value
		if product % 2 != 0 do return INVALID_RESULT
		return product / 2
	}
	if operation == 3 {
		product := a * b * c_value
		if product % 3 != 0 do return INVALID_RESULT
		return product / 3
	}
	return INVALID_RESULT
}
