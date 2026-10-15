package number_appearing_odd_times

import "core:c"

MAX_LENGTH :: 4096
INVALID_RESULT :: i64 = -2_147_483_649

// XOR-fold an int32 array to find its unique odd-frequency value.
@(export)
number_appearing_odd_times :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > c.size_t(MAX_LENGTH) || values == nil do return INVALID_RESULT
	result := i32(0)
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return INVALID_RESULT
		result = result ~ i32(value)
	}
	return i64(result)
}
