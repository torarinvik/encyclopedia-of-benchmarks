package count_consonants

import "core:c"

MAX_LENGTH :: 4096

@(export)
count_consonants :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > c.size_t(MAX_LENGTH) || values == nil do return -1
	if length == 1 && values[0] == 48 do return -1
	count := i64(0)
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 32 || value > 126 do return -1
		if value >= 65 && value <= 90 do value += 32
		if value >= 97 && value <= 122 && value != 97 && value != 101 && value != 105 && value != 111 && value != 117 do count += 1
	}
	return count
}
