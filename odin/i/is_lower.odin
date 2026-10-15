package is_lower

import "core:c"

MAX_LENGTH :: 4096

@(export)
is_lower :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -1
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 32 || value > 126 do return -1
		if value >= 65 && value <= 90 do return 0
	}
	return 1
}
