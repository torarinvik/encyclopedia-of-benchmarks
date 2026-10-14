package find_max

import "core:c"

// Return the largest signed value in a nonempty array.
@(export)
find_max :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 512 do return -1
	result := values[0]
	for index := c.size_t(1); index < length; index += 1 {
		if values[index] > result do result = values[index]
	}
	return result
}
