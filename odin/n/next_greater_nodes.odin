package next_greater_nodes

import "core:c"

@(export)
next_greater_nodes :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > 4096 || values == nil do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < 1 || values[index] > 1_000_000_000 do return -1
	}
	required := 4 * length
	if output_capacity < required || output == nil do return -2
	for index := c.size_t(0); index < length; index += 1 {
		next_greater := i64(0)
		for later := index + 1; later < length; later += 1 {
			if values[later] > values[index] {
				next_greater = values[later]
				break
			}
		}
		encoded := u32(next_greater)
		output[4 * index] = u8(encoded & 0xff)
		output[4 * index + 1] = u8((encoded >> 8) & 0xff)
		output[4 * index + 2] = u8((encoded >> 16) & 0xff)
		output[4 * index + 3] = u8((encoded >> 24) & 0xff)
	}
	return i64(length)
}
