package upper

import "core:c"

@(export)
upper :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if length > 256 || (length > 0 && input == nil) do return -1
	for i := 0; i < int(length); i += 1 { if input[i] < 0 || input[i] > 127 || input[i] == 9 || input[i] == 10 || input[i] == 11 || input[i] == 12 || input[i] == 13 || input[i] == 32 do return -1 }
	if int(capacity) < int(length) || (length > 0 && output == nil) do return -2
	for i := 0; i < int(length); i += 1 { output[i] = u8(input[i]) }
	for i := 0; i < int(length); i += 1 { if output[i] >= u8('a') && output[i] <= u8('z') do output[i] -= 32 }
	return i64(length)
}
