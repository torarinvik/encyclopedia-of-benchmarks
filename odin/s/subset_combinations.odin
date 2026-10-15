package subset_combinations

import "core:c"

// Emit fixed-size index combinations as little-endian subset masks.
@(export)
subset_combinations :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > 13 || input[0] < 0 do return -1
	item_count := length - 1
	if item_count > 12 do return -1
	if input[0] > i64(item_count) do return 0
	choose := c.size_t(input[0])
	count: c.size_t = 1
	for index: c.size_t = 1; index <= choose; index += 1 {
		count = count * (item_count - choose + index) / index
	}
	required := 2 * count
	if output_capacity < required || output == nil do return -2
	indices: [12]c.size_t
	for index: c.size_t = 0; index < choose; index += 1 { indices[index] = index }
	for combination: c.size_t = 0; combination < count; combination += 1 {
		mask: c.size_t = 0
		for index: c.size_t = 0; index < choose; index += 1 { mask |= c.size_t(1) << indices[index] }
		output[2 * combination] = u8(mask % 256)
		output[2 * combination + 1] = u8(mask / 256)
		if combination + 1 == count do break
		position := choose
		for position > 0 {
			position -= 1
			if indices[position] < item_count - choose + position do break
		}
		indices[position] += 1
		for index := position + 1; index < choose; index += 1 { indices[index] = indices[index - 1] + 1 }
	}
	return i64(count)
}
