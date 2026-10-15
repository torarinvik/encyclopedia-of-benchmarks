package reverse_string

import "core:c"

@(export)
reverse_string :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	if input[0] < 0 || input[0] > 256 do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	for index := 0; index < n; index += 1 {
		if input[index + 1] < 33 || input[index + 1] > 126 do return -1
	}
	if output == nil || output_capacity < c.size_t(n + 1) do return -2
	for index := 0; index < n; index += 1 {
		output[index] = u8(input[n - index])
	}
	output[n] = 0
	return i64(n)
}
