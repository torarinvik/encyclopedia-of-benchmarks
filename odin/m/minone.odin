package minone

import "core:c"

MAX_LENGTH :: 64
MIN_VALUE :: i64(-1_000_000)
MAX_VALUE :: i64(1_000_000)

@(export, link_name="minone")
minone :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_LENGTH do return -1
	total := i64(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := input[index]
		if value < MIN_VALUE || value > MAX_VALUE do return -1
		total += value * value
	}
	return total
}
