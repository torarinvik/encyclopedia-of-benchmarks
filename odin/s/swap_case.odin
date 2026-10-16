package swap_case

import "core:c"

MAX_INPUT_LENGTH :: 4096

@(export)
swap_case :: proc "c" (input: [^]i64, length: c.size_t,
                        output: [^]u8, capacity: c.size_t) -> i64 {
	if length > MAX_INPUT_LENGTH || (length > 0 && input == nil) do return -1
	for i := 0; i < int(length); i += 1 {
		if input[i] < 0 || input[i] > 127 do return -1
	}
	if length > capacity || (length > 0 && output == nil) do return -2
	for i := 0; i < int(length); i += 1 {
		value := input[i]
		if value >= 65 && value <= 90 do value += 32
		else if value >= 97 && value <= 122 do value -= 32
		output[i] = u8(value)
	}
	return i64(length)
}
