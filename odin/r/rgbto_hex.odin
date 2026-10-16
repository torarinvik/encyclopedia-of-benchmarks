package rgbto_hex

import "core:c"

RGB_CHANNEL_COUNT :: 3
RGB_HEX_OUTPUT_LENGTH :: 7

hex_digit :: proc "contextless" (value: i64) -> u8 {
	if value < 10 do return u8(48 + value)
	return u8(87 + value)
}

@(export)
rgbto_hex :: proc "c" (input: [^]i64, length: c.size_t,
                        output: [^]u8, capacity: c.size_t) -> i64 {
	if length != RGB_CHANNEL_COUNT || input == nil do return -1
	for i := 0; i < RGB_CHANNEL_COUNT; i += 1 {
		if input[i] < 0 || input[i] > 255 do return -1
	}
	if capacity < RGB_HEX_OUTPUT_LENGTH || output == nil do return -2
	output[0] = u8('#')
	for i := 0; i < RGB_CHANNEL_COUNT; i += 1 {
		output[1 + 2 * i] = hex_digit(input[i] >> 4)
		output[2 + 2 * i] = hex_digit(input[i] & 15)
	}
	return i64(RGB_HEX_OUTPUT_LENGTH)
}
