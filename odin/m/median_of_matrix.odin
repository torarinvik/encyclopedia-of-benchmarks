package median_of_matrix

import "core:c"

MAX_ROWS :: 16
MAX_CELLS :: 128
MAX_INPUT_WORDS :: 1 + MAX_ROWS + MAX_CELLS

put_i32_le :: proc "contextless" (output: [^]u8, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[byte] = u8(bits >> u32(8*byte))
	}
}

@(export)
median_of_matrix :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_WORDS) do return -1
	if input[0] < 0 || input[0] > MAX_ROWS do return -1

	row_count := int(input[0])
	cursor := 1
	value_count := 0
	values: [MAX_CELLS]i32
	for row := 0; row < row_count; row += 1 {
		if cursor >= int(length) do return -1
		row_length := input[cursor]
		cursor += 1
		if row_length == -1 do continue
		if row_length < 0 || row_length > MAX_CELLS do return -1
		cells := int(row_length)
		if cells > MAX_CELLS-value_count || cells > int(length)-cursor do return -1
		for column := 0; column < cells; column += 1 {
			value := input[cursor]
			cursor += 1
			if value < -2_147_483_648 || value > 2_147_483_647 do return -1
			values[value_count] = i32(value)
			value_count += 1
		}
	}
	if cursor != int(length) || value_count == 0 do return -1

	for index := 1; index < value_count; index += 1 {
		value := values[index]
		position := index
		for position > 0 && values[position-1] > value {
			values[position] = values[position-1]
			position -= 1
		}
		values[position] = value
	}

	if output == nil || capacity < 4 do return -2
	buffer: [4]u8
	put_i32_le(&buffer[0], values[(value_count-1)/2])
	for byte := 0; byte < 4; byte += 1 do output[byte] = buffer[byte]
	return 4
}
