package check_flat_case

import "core:c"

MAX_LENGTH :: 4096

// Check whether the bounded ASCII input is entirely lowercase letters.
@(export)
check_flat_case :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -2
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 32 || value > 126 do return -2
	}
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 97 || value > 122 do return 0
	}
	return 1
}
