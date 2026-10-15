package is_contains_unique_chars

import "core:c"

MAX_LENGTH :: 4096

@(export)
is_contains_unique_chars :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -1
	for index := 0; index < int(length); index += 1 {
		if values[index] < 0 || values[index] > 127 do return -1
	}
	seen: [2]u64 = {0, 0}
	for index := 0; index < int(length); index += 1 {
		value := u64(values[index])
		word := int(value / 64)
		mask := u64(1) << u64(value % 64)
		if (seen[word] & mask) != 0 do return 0
		seen[word] |= mask
	}
	return 1
}
