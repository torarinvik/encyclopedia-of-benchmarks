package adfgvxcipher

import "core:c"

MAX_PLAINTEXT :: 256
MAX_CIPHERTEXT :: 512
MAX_KEY :: 16
MAX_ROWS :: 512
LABELS :: "ADFGVX"
SQUARE :: "NA1C3H8TB2OME5WRPD4F6G7I9J0KLQSUVXYZ"

polybius_cell :: proc(value: u8) -> int {
	for cell := 0; cell < 36; cell += 1 {
		if SQUARE[cell] == value do return cell
	}
	return -1
}

label_index :: proc(value: u8) -> int {
	for index := 0; index < 6; index += 1 {
		if LABELS[index] == value do return index
	}
	return -1
}

@(export)
adfgvxcipher :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	mode, text_length_value, key_length_value := input[0], input[1], input[2]
	if (mode != 0 && mode != 1) || text_length_value < 0 || key_length_value < 1 || key_length_value > MAX_KEY do return -1
	text_length := int(text_length_value)
	key_length := int(key_length_value)
	if (mode == 0 && text_length > MAX_PLAINTEXT) || (mode == 1 && text_length > MAX_CIPHERTEXT) ||
		length != c.size_t(3 + text_length + key_length) do return -1
	for index := 0; index < text_length; index += 1 {
		if input[3 + index] < 0 || input[3 + index] > 127 do return -1
		if mode == 1 && label_index(u8(input[3 + index])) < 0 do return -1
	}
	if mode == 1 && text_length % 2 != 0 do return -1
	key_start := 3 + text_length
	for index := 0; index < key_length; index += 1 {
		if input[key_start + index] < 65 || input[key_start + index] > 90 do return -1
		for previous := 0; previous < index; previous += 1 {
			if input[key_start + index] == input[key_start + previous] do return -1
		}
	}

	order: [MAX_KEY]int
	for index := 0; index < key_length; index += 1 do order[index] = index
	for index := 1; index < key_length; index += 1 {
		current := order[index]
		position := index
		for position > 0 && input[key_start + order[position - 1]] > input[key_start + current] {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = current
	}

	result: [MAX_CIPHERTEXT]u8
	result_length := 0
	if mode == 0 {
		fractionated: [MAX_CIPHERTEXT]u8
		fractionated_length := 0
		for index := 0; index < text_length; index += 1 {
			value := u8(input[3 + index])
			if value >= u8('a') && value <= u8('z') do value -= u8(32)
			if !((value >= u8('A') && value <= u8('Z')) || (value >= u8('0') && value <= u8('9'))) do continue
			cell := polybius_cell(value)
			if cell < 0 do return -1
			fractionated[fractionated_length] = LABELS[cell / 6]
			fractionated[fractionated_length + 1] = LABELS[cell % 6]
			fractionated_length += 2
		}
		rows := (fractionated_length + key_length - 1) / key_length
		table: [MAX_ROWS * MAX_KEY]u8
		for row := 0; row < rows; row += 1 {
			for column := 0; column < key_length; column += 1 do table[row * MAX_KEY + column] = '_'
		}
		for index := 0; index < fractionated_length; index += 1 do table[(index / key_length) * MAX_KEY + index % key_length] = fractionated[index]
		for order_index := 0; order_index < key_length; order_index += 1 {
			column := order[order_index]
			for row := 0; row < rows; row += 1 {
				value := table[row * MAX_KEY + column]
				if value != '_' { result[result_length] = value; result_length += 1 }
			}
		}
	} else {
		rows := (text_length + key_length - 1) / key_length
		table: [MAX_ROWS * MAX_KEY]u8
		source_index := 0
		for order_index := 0; order_index < key_length; order_index += 1 {
			column := order[order_index]
			for row := 0; row < rows; row += 1 {
				if source_index < text_length {
					table[row * MAX_KEY + column] = u8(input[3 + source_index])
					source_index += 1
				} else {
					table[row * MAX_KEY + column] = '_'
				}
			}
		}
		fractionated: [MAX_CIPHERTEXT]u8
		fractionated_length := 0
		for row := 0; row < rows; row += 1 {
			for column := 0; column < key_length; column += 1 {
				value := table[row * MAX_KEY + column]
				if value != '_' { fractionated[fractionated_length] = value; fractionated_length += 1 }
			}
		}
		for index := 0; index < fractionated_length; index += 2 {
			row := label_index(fractionated[index])
			column := label_index(fractionated[index + 1])
			if row < 0 || column < 0 do return -1
			result[result_length] = SQUARE[row * 6 + column]
			result_length += 1
		}
	}
	if output_capacity < c.size_t(result_length) || (result_length > 0 && output == nil) do return -2
	for index := 0; index < result_length; index += 1 do output[index] = result[index]
	return i64(result_length)
}
