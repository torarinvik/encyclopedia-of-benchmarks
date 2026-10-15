package median

import "core:c"

// Return twice the statistical median using a local insertion-sorted copy.
@(export)
median :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > c.size_t(1024) do return 0
	ordered: [1024]i64
	for index := 0; index < int(length); index += 1 { ordered[index] = values[index] }
	for index := 1; index < int(length); index += 1 {
		value := ordered[index]
		cursor := index
		for cursor > 0 && ordered[cursor - 1] > value {
			ordered[cursor] = ordered[cursor - 1]
			cursor -= 1
		}
		ordered[cursor] = value
	}
	n := int(length)
	if n % 2 != 0 do return ordered[n / 2] * 2
	return ordered[n / 2 - 1] + ordered[n / 2]
}
