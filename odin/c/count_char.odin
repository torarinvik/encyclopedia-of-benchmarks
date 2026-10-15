package count_char

import "core:c"

@(export)
count_char :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 4096 || (length != 0 && values == nil) do return -1
	count: i64 = 0
	for i in 0..<length {
		code := values[i]
		if code < 0 || code > 127 do return -1
		if code != 9 && code != 10 && code != 11 && code != 12 && code != 13 && code != 32 {
			count += 1
		}
	}
	return count
}
