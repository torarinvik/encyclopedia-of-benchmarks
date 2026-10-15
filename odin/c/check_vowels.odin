package check_vowels

import "core:c"

MAX_LENGTH :: 4096

// Return whether any lowercase ASCII vowel appears in the input.
@(export)
check_vowels :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length > 0 && values == nil) do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if values[i] < 97 || values[i] > 122 do return -1
	}
	for i := c.size_t(0); i < length; i += 1 {
		value := values[i]
		if value == 97 || value == 101 || value == 105 || value == 111 || value == 117 do return 1
	}
	return 0
}
