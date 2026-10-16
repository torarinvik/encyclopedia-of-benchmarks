package how_many_times_rotated

import "core:c"

MAX_ARRAY_LENGTH :: 256
MAX_INPUT_LENGTH :: MAX_ARRAY_LENGTH + 1

@(export)
how_many_times_rotated :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if length > c.size_t(MAX_ARRAY_LENGTH) do return -1
	if length == 0 do return 0
	if input == nil do return -1
	for index := 0; index < int(length); index += 1 {
		if input[index] < -2147483648 || input[index] > 2147483647 do return -1
	}

	low := 0
	high := int(length)
	if high > 0 do high -= 1
	for low < high {
		middle := low + (high - low) / 2
		if input[middle] > input[high] do low = middle + 1
		else do high = middle
	}
	return i64(low)
}
