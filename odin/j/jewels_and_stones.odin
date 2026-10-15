package jewels_and_stones

import "core:c"

MAX_JEWELS_LENGTH :: 127
MAX_STONES_LENGTH :: 4096
MAX_PACKED_LENGTH :: 4225

// Count stones whose ASCII byte appears in the unique-jewel set.
@(export)
jewels_and_stones :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PACKED_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_JEWELS_LENGTH || input[1] < 0 || input[1] > MAX_STONES_LENGTH do return -1
	jewel_count := c.size_t(input[0])
	stone_count := c.size_t(input[1])
	if length != 2 + jewel_count + stone_count do return -1
	counts: [128]i64 = {}
	for index := c.size_t(0); index < jewel_count; index += 1 {
		value := input[2 + index]
		if value < 1 || value > 127 do return -1
		if counts[int(value)] != 0 do return -1
		counts[int(value)] = 1
	}
	total := i64(0)
	stone_start := 2 + jewel_count
	for index := c.size_t(0); index < stone_count; index += 1 {
		value := input[stone_start + index]
		if value < 1 || value > 127 do return -1
		total += counts[int(value)]
	}
	return total
}
