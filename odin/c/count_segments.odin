package count_segments

import "core:c"

// Count transitions from ASCII space to a non-space byte.
@(export)
count_segments :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > 4096 || (length != 0 && input == nil) do return -1
	count := i64(0)
	previous_was_space := true
	for index := c.size_t(0); index < length; index += 1 {
		value := input[index]
		if value < 1 || value > 127 do return -1
		if value != 32 && previous_was_space do count += 1
		previous_was_space = value == 32
	}
	return count
}
