package ones_complement

import "core:c"

MAX_INPUT_LENGTH :: 64

@(export)
ones_complement :: proc "c" (input: [^]i64, length: c.size_t,
                              output: [^]u8, capacity: c.size_t) -> i64 {
	if length == 0 || length > MAX_INPUT_LENGTH || input == nil do return -1
	for i := 0; i < int(length); i += 1 {
		if input[i] != 48 && input[i] != 49 do return -1
	}
	if length > capacity || output == nil do return -2
	for i := 0; i < int(length); i += 1 {
		if input[i] == 48 do output[i] = 49
		else do output[i] = 48
	}
	return i64(length)
}
