package sepia

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 196
MAX_OUTPUT_BYTES :: 192

@(export)
sepia :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	height, width, factor := input[0], input[1], input[2]
	if height < 1 || height > 8 || width < 1 || width > 8 || factor < 0 || factor > 255 do return -1
	pixels := int(height * width)
	if input_length != c.size_t(3 + 3 * pixels) do return -1
	for index := 0; index < 3 * pixels; index += 1 {
		channel := input[3 + index]
		if channel != 0 && channel != 64 && channel != 128 && channel != 255 do return -1
	}

	staged: [MAX_OUTPUT_BYTES]u8
	for pixel := 0; pixel < pixels; pixel += 1 {
		offset := 3 + 3 * pixel
		blue, green, red := f64(input[offset]), f64(input[offset + 1]), f64(input[offset + 2])
		gray := i64(0.2126 * red + 0.587 * green + 0.114 * blue)
		staged[3 * pixel] = u8(gray)
		tinted_green := gray + factor
		if tinted_green > 255 do tinted_green = 255
		tinted_red := gray + 2 * factor
		if tinted_red > 255 do tinted_red = 255
		staged[3 * pixel + 1], staged[3 * pixel + 2] = u8(tinted_green), u8(tinted_red)
	}

	output_bytes := 3 * pixels
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
