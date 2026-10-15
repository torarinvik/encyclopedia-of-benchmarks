package longest_substring_without_repeating_characters

import "core:c"

MAX_LENGTH :: 1024
ALPHABET_SIZE :: 95

// Return the longest printable-ASCII substring with no repeated byte.
@(export)
longest_substring_without_repeating_characters :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -2
	last_seen: [ALPHABET_SIZE]i64
	for slot := 0; slot < ALPHABET_SIZE; slot += 1 { last_seen[slot] = -1 }
	window_start: int = 0
	longest: int = 0
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 32 || value > 126 do return -2
		slot := int(value - 32)
		previous := last_seen[slot]
		if previous >= 0 && int(previous) >= window_start do window_start = int(previous) + 1
		last_seen[slot] = i64(index)
		current := index - window_start + 1
		if current > longest do longest = current
	}
	return i64(longest)
}
