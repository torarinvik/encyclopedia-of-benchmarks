package count_vowels

import "core:c"

MAX_LENGTH :: 4096

// Count ASCII vowels in a bounded string represented by byte values.
@(export)
count_vowels :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > c.size_t(MAX_LENGTH) || values == nil do return -2
	if length == 1 && values[0] == 48 do return -2
	count: i64 = 0
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 0 || value > 127 || value == 44 do return -2
		if value == 97 || value == 101 || value == 105 || value == 111 || value == 117 || value == 65 || value == 69 || value == 73 || value == 79 || value == 85 {
			count += 1
		}
	}
	return count
}
