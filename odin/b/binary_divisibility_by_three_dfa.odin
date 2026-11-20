package binary_divisibility_by_three_dfa

import "core:c"

@(export)
binary_divisibility_by_three_dfa :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > 4098 do return -1
	bit_count := input[0]
	if bit_count < 1 || bit_count > 4096 || length != c.size_t(bit_count + 1) do return -1
	remainder: i64 = 0
	for index := c.size_t(1); index < length; index += 1 {
		if input[index] != 0 && input[index] != 1 do return -1
		remainder = (2 * remainder + input[index]) % 3
	}
	if output == nil || output_capacity < 1 do return -2

	output[0] = u8(0)
	if remainder == 0 do output[0] = u8(1)
	return 1
}
