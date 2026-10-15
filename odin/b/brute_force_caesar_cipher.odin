package brute_force_caesar_cipher

import "core:c"

MAX_MESSAGE_LENGTH :: 64
KEY_COUNT :: 26

@(export)
brute_force_caesar_cipher :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if length > MAX_MESSAGE_LENGTH || (length > 0 && input == nil) do return -1
	for i := c.size_t(0); i < length; i += 1 { if input[i] < 0 || input[i] > 127 do return -1 }
	needed := length * KEY_COUNT + (KEY_COUNT - 1)
	if output == nil || capacity < needed do return -2
	position: c.size_t = 0
	for key := c.size_t(0); key < KEY_COUNT; key += 1 {
		for i := c.size_t(0); i < length; i += 1 {
			value := input[i]
			if value >= 65 && value <= 90 { value = 65 + (value - 65 + 26 - i64(key)) % 26 }
			output[position] = u8(value)
			position += 1
		}
		if key + 1 < KEY_COUNT { output[position] = 10; position += 1 }
	}
	return i64(KEY_COUNT)
}
