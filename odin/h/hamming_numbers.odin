package hamming_numbers

import "core:c"

MAX_COUNT :: 32

@(export)
hamming_numbers :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 1 || input[0] < 1 || input[0] > MAX_COUNT do return -1
	count := c.size_t(input[0])
	output_bytes := count * 8
	if output_capacity < output_bytes || output == nil do return -2

	values: [MAX_COUNT]u64
	values[0] = 1
	i2, i3, i5 := c.size_t(0), c.size_t(0), c.size_t(0)
	for index := c.size_t(1); index < count; index += 1 {
		c2 := values[i2] * 2
		c3 := values[i3] * 3
		c5 := values[i5] * 5
		next := min(c2, c3)
		if c5 < next do next = c5
		values[index] = next
		if c2 == next do i2 += 1
		if c3 == next do i3 += 1
		if c5 == next do i5 += 1
	}
	for index := c.size_t(0); index < count; index += 1 {
		for byte := c.size_t(0); byte < 8; byte += 1 {
			output[index * 8 + byte] = u8(values[index] >> (byte * 8))
		}
	}
	return i64(count)
}
