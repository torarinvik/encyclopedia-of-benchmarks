package first_unique_character

import "core:c"

MAX_LENGTH :: 1024

// Return the first lowercase ASCII letter whose frequency is one.
@(export)
first_unique_character :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -2
	counts: [26]int
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 97 || value > 122 do return -2
		counts[int(value - 97)] += 1
	}
	for index := 0; index < int(length); index += 1 {
		if counts[int(values[index] - 97)] == 1 do return i64(index)
	}
	return -1
}
