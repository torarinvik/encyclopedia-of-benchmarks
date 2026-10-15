package capitalize

import "core:c"

@(export)
capitalize :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if length > 256 || (length > 0 && input == nil) do return -1
	for i := 0; i < int(length); i += 1 { if input[i] < 0 || input[i] > 127 do return -1 }
	if int(capacity) < int(length) || (length > 0 && output == nil) do return -2
	for i := 0; i < int(length); i += 1 { output[i] = u8(input[i]) }
	if length > 0 && output[0] >= u8('a') && output[0] <= u8('z') do output[0] -= 32
	return i64(length)
}
