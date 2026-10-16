package flip_augmentation

import "core:c"

MAX_INPUT_LENGTH :: 340
COORDINATE_SCALE :: 1_000_000

store_i32_le :: proc(output: [^]u8, position: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 { output[position + byte] = u8((bits >> u32(byte * 8)) & 255) }
}

@(export)
flip_augmentation :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	if values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16 do return -1
	if (values[2] != 0 && values[2] != 1) || values[3] < 0 || values[3] > 16 do return -1
	width, height, flip_type, box_count := int(values[0]), int(values[1]), int(values[2]), int(values[3])
	pixel_count := width * height
	if int(length) != 4 + pixel_count + 5 * box_count do return -1
	for index := 0; index < pixel_count; index += 1 {
		if values[4 + index] < 0 || values[4 + index] > 255 do return -1
	}
	for box := 0; box < box_count; box += 1 {
		base := 4 + pixel_count + 5 * box
		if values[base] < 0 || values[base] > 2147483647 do return -1
		for field := 1; field < 5; field += 1 {
			if values[base + field] < 0 || values[base + field] > COORDINATE_SCALE do return -1
		}
	}
	output_bytes := pixel_count + 20 * box_count
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	for row := 0; row < height; row += 1 {
		for column := 0; column < width; column += 1 {
			source_row := row
			source_column := column
			if flip_type == 0 do source_row = height - 1 - row
			if flip_type == 1 do source_column = width - 1 - column
			output[row * width + column] = u8(values[4 + source_row * width + source_column])
		}
	}
	for box := 0; box < box_count; box += 1 {
		base := 4 + pixel_count + 5 * box
		output_base := pixel_count + 20 * box
		for field := 0; field < 5; field += 1 {
			value := values[base + field]
			if flip_type == 1 && field == 1 do value = COORDINATE_SCALE - value
			if flip_type == 0 && field == 2 do value = COORDINATE_SCALE - value
			store_i32_le(output, output_base + 4 * field, i32(value))
		}
	}
	return i64(output_bytes)
}
