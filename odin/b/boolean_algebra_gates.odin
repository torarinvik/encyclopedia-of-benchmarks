package boolean_algebra_gates

import "core:c"

MAX_INPUT_COUNT :: 4096
INVALID_RESULT :: i64 = -1

@(export)
boolean_algebra_gates :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_INPUT_COUNT + 2) do return INVALID_RESULT
	gate := values[0]
	count := values[1]
	if gate < 0 || gate > 5 || count < 0 || count > MAX_INPUT_COUNT do return INVALID_RESULT
	if c.size_t(count) != length - 2 do return INVALID_RESULT
	if gate == 2 && count != 1 do return INVALID_RESULT
	result := i64(0)
	if gate == 0 || gate == 4 do result = 1
	for index := 0; index < int(count); index += 1 {
		bit := values[index + 2]
		if bit != 0 && bit != 1 do return INVALID_RESULT
		if gate == 0 || gate == 4 do result &= bit
		else if gate == 1 || gate == 5 do result |= bit
		else if gate == 2 do result = 1 - bit
		else do result = result ~ bit
	}
	if gate == 4 || gate == 5 do result = 1 - result
	return result
}
