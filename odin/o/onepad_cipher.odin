package onepad_cipher

import "core:c"

MAX_TEXT_LENGTH :: 1024

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
onepad_cipher :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH do return -1
	mode, count_value := input[0], input[1]
	if (mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH do return -1
	count := c.size_t(count_value)
	if length != 2 + 2 * count do return -1
	needed := c.size_t(count)
	if mode == 0 do needed = 8 * count
	if output_capacity < needed do return -2
	for index := c.size_t(0); index < count; index += 1 {
		data, key := input[2 + index], input[2 + count + index]
		if key < 1 || key > 300 do return -1
		if mode == 0 {
			if data < 32 || data > 126 do return -1
			store_i64_le(output, 8 * int(index), (data + key) * key)
		} else {
			key_square := key * key
			if data < key_square || (data - key_square) % key != 0 do return -1
			plain := (data - key_square) / key
			if plain < 32 || plain > 126 do return -1
			output[index] = u8(plain)
		}
	}
	return i64(needed)
}
