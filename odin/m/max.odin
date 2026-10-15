package max

import "core:c"

const MAX_VALUES = 256
const INVALID_RESULT: i64 = -9223372036854775807 - 1

@(export)
max_values :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_VALUES + 1 do return INVALID_RESULT
	count := values[0]
	if count < 1 || count > MAX_VALUES || length != c.size_t(count + 1) do return INVALID_RESULT
	result := values[1]
	if result < -2147483648 || result > 2147483647 do return INVALID_RESULT
	for index := 2; index < int(length); index += 1 {
		value := values[index]
		if value < -2147483648 || value > 2147483647 do return INVALID_RESULT
		if value > result do result = value
	}
	return result
}
