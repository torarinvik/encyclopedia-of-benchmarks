package gramian

import "core:c"

MAX_INPUT_LENGTH :: 27

write_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u64(byte*8))
	}
}

gram_matrix :: proc "contextless" (values: [^]i64, channels, pixels, part: int,
		result: ^[9]f64) {
	feature_count := channels * pixels
	for row := 0; row < channels; row += 1 {
		for column := 0; column < channels; column += 1 {
			dot := 0.0
			for pixel := 0; pixel < pixels; pixel += 1 {
				row_index := 3 + part*feature_count + row*pixels + pixel
				column_index := 3 + part*feature_count + column*pixels + pixel
				row_value := f64(values[row_index]) / 1000.0
				column_value := f64(values[column_index]) / 1000.0
				dot += row_value * column_value
			}
			result^[row*channels+column] = dot / f64(feature_count)
		}
	}
}

@(export)
gramian :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	operation, raw_channels, raw_pixels := values[0], values[1], values[2]
	if (operation != 0 && operation != 1) || raw_channels < 1 || raw_channels > 3 ||
		raw_pixels < 1 || raw_pixels > 4 do return -1
	channels, pixels := int(raw_channels), int(raw_pixels)
	feature_count := channels * pixels
	map_count := if operation == 1 do 2 else 1
	if length != c.size_t(3 + feature_count*map_count) do return -1
	for index := 3; index < int(length); index += 1 {
		if values[index] < -1000 || values[index] > 1000 do return -1
	}
	output_count := if operation == 1 do 1 else channels*channels
	required := output_count * 8
	if output == nil || output_capacity < c.size_t(required) do return -2

	first: [9]f64
	gram_matrix(values, channels, pixels, 0, &first)
	if operation == 0 {
		for index := 0; index < output_count; index += 1 {
			write_f64_le(output, index*8, first[index])
		}
	} else {
		second: [9]f64
		gram_matrix(values, channels, pixels, 1, &second)
		loss := 0.0
		for index := 0; index < channels*channels; index += 1 {
			difference := first[index] - second[index]
			loss += difference * difference
		}
		write_f64_le(output, 0, loss)
	}
	return i64(required)
}
