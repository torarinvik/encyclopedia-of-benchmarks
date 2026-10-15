package detect_capital_usage

import "core:c"

MAX_LENGTH :: 1024
is_upper :: proc "c" (value: i64) -> bool { return value >= 65 && value <= 90 }
is_lower :: proc "c" (value: i64) -> bool { return value >= 97 && value <= 122 }

// Classify capitalization by counting uppercase letters.
@(export)
detect_capital_usage :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	uppercase_count := c.size_t(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := input[index]
		if !is_upper(value) && !is_lower(value) do return -1
		if is_upper(value) do uppercase_count += 1
	}
	if uppercase_count == 0 || uppercase_count == length || (uppercase_count == 1 && length != 0 && is_upper(input[0])) do return 1
	return 0
}
