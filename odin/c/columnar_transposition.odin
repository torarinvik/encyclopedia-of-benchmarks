package columnar_transposition

import "core:c"

MAX_TEXT :: 256
MAX_KEY :: 32

@(export)
columnar_transposition :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 { return -1 }
	operation, text_value, raw_key_value := input[0], input[1], input[2]
	if (operation != 0 && operation != 1) || text_value < 0 || text_value > MAX_TEXT || raw_key_value < 1 || raw_key_value > MAX_KEY { return -1 }
	text_length, raw_key_length := int(text_value), int(raw_key_value)
	if length != c.size_t(3 + text_length + raw_key_length) { return -1 }
	key: [MAX_KEY]u8
	order: [MAX_KEY]int
	key_length := 0
	for index := 0; index < text_length; index += 1 { if input[3 + index] < 0 || input[3 + index] > 127 { return -1 } }
	for index := 0; index < raw_key_length; index += 1 {
		value := input[3 + text_length + index]
		if value < 0 || value > 127 { return -1 }
		if value >= 65 && value <= 90 { key[key_length] = u8(value); key_length += 1
		} else if value >= 97 && value <= 122 { key[key_length] = u8(value - 32); key_length += 1 }
	}
	if key_length == 0 { return -1 }
	for index := 0; index < key_length; index += 1 {
		order[index] = index
		position := index
		for position > 0 && key[order[position - 1]] > key[index] {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = index
	}
	if text_length == 0 { return 0 }
	if output == nil || capacity < c.size_t(text_length) { return -2 }
	rows := (text_length + key_length - 1) / key_length
	if operation == 0 {
		written := 0
		for rank := 0; rank < key_length; rank += 1 {
			column := order[rank]
			for row := 0; row < rows; row += 1 {
				index := row * key_length + column
				if index < text_length { output[written] = u8(input[3 + index]); written += 1 }
			}
		}
		return i64(written)
	}
	column_data: [MAX_KEY * MAX_TEXT]u8
	column_lengths: [MAX_KEY]int
	offset := 0
	short_columns := text_length % key_length
	for column := 0; column < key_length; column += 1 {
		column_lengths[column] = rows
		if short_columns != 0 && column >= short_columns { column_lengths[column] = rows - 1 }
	}
	for rank := 0; rank < key_length; rank += 1 {
		column := order[rank]
		for row := 0; row < column_lengths[column]; row += 1 { column_data[column * MAX_TEXT + row] = u8(input[3 + offset]); offset += 1 }
	}
	written := 0
	for row := 0; row < rows; row += 1 {
		for column := 0; column < key_length; column += 1 {
			if row < column_lengths[column] { output[written] = column_data[column * MAX_TEXT + row]; written += 1 }
		}
	}
	return i64(written)
}
