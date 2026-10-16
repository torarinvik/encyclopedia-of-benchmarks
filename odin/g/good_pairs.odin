package good_pairs

import "core:c"

MAX_N :: 256
VALUE_LIMIT :: i64(1_000_000)

@(export)
good_pairs :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length == 0 || length > c.size_t(MAX_N + 1) do return -1
	n := packed[0]
	if n < 0 || n > MAX_N || length != c.size_t(n) + 1 do return -1
	for index := 0; index < int(n); index += 1 {
		value := packed[index + 1]
		if value < -VALUE_LIMIT || value > VALUE_LIMIT do return -1
	}
	count := i64(0)
	for i := 0; i < int(n); i += 1 {
		for j := i + 1; j < int(n); j += 1 {
			if packed[i + 1] == packed[j + 1] do count += 1
		}
	}
	return count
}
