package binary_and_operator

import "core:c"

@(export)
binary_and_operator :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	a_value, b_value := input[0], input[1]
	if a_value < 0 || a_value > 2147483647 || b_value < 0 || b_value > 2147483647 do return -1
	a, b := u64(a_value), u64(b_value)
	largest := max(a, b)
	width := 1
	for largest > 1 { largest >>= 1; width += 1 }
	output_length := width + 2
	if int(capacity) < output_length || output == nil do return -2
	output[0] = u8('0'); output[1] = u8('b')
	result := a & b
	for i := 0; i < width; i += 1 {
		bit := width - 1 - i
		if ((result >> u64(bit)) & 1) == 1 do output[2+i] = u8('1') else output[2+i] = u8('0')
	}
	return i64(output_length)
}
