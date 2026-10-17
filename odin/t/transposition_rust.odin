package transposition_rust

import "core:c"

MAX_KEYS :: 4
MAX_KEY_LENGTH :: 32
MAX_MESSAGE_LENGTH :: 256
MAX_INPUT_LENGTH :: 3 + MAX_KEYS + MAX_KEYS * MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH
MAX_OUTPUT_LENGTH :: 2 * MAX_MESSAGE_LENGTH - 1
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)
LOW63_MASK :: u64(0x7fffffffffffffff)

is_ascii_letter :: proc "contextless" (value: i64) -> bool {
	return (value >= i64('A') && value <= i64('Z')) || (value >= i64('a') && value <= i64('z'))
}

normalize :: proc "contextless" (input: [^]u8, length: int, output: [^]u8) -> int {
	count := 0
	for i := 0; i < length; i += 1 {
		ch := input[i]
		if ch >= u8('a') && ch <= u8('z') { ch = ch - u8('a' - 'A') }
		if ch >= u8('A') && ch <= u8('Z') { output[count] = ch; count += 1 }
	}
	return count
}

column_order :: proc "contextless" (key: [^]u8, key_length: int, order: [^]int) {
	for i := 0; i < key_length; i += 1 { order[i] = i }
	for i := 1; i < key_length; i += 1 {
		column := order[i]
		position := i
		for position > 0 && key[order[position - 1]] > key[column] {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = column
	}
}

encrypt_round :: proc "contextless" (text: [^]u8, text_length: int,
		key: [^]u8, key_length: int, output: [^]u8) -> int {
	var order: [MAX_KEY_LENGTH]int
	var columns: [MAX_MESSAGE_LENGTH]u8
	column_order(key, key_length, &order[0])
	ordered_length := 0
	for rank := 0; rank < key_length; rank += 1 {
		for position := order[rank]; position < text_length; position += key_length {
			columns[ordered_length] = text[position]
			ordered_length += 1
		}
	}
	group_size := (text_length + key_length - 1) / key_length
	output_length := 0
	for i := 0; i < ordered_length; i += 1 {
		output[output_length] = columns[i]
		output_length += 1
		if (i + 1) % group_size == 0 && i + 1 < ordered_length { output[output_length] = u8(' '); output_length += 1 }
	}
	return output_length
}

decrypt_round :: proc "contextless" (text: [^]u8, text_length: int,
		key: [^]u8, key_length: int, output: [^]u8) -> int {
	var order: [MAX_KEY_LENGTH]int
	var columns: [MAX_KEY_LENGTH][MAX_MESSAGE_LENGTH]u8
	var column_lengths: [MAX_KEY_LENGTH]int
	column_order(key, key_length, &order[0])
	short_length := text_length / key_length
	longer_columns := text_length % key_length
	cursor := 0
	for rank := 0; rank < key_length; rank += 1 {
		column := order[rank]
		column_length := short_length
		if column < longer_columns { column_length += 1 }
		column_lengths[column] = column_length
		for row := 0; row < column_length; row += 1 { columns[column][row] = text[cursor]; cursor += 1 }
	}
	row_count := short_length
	if longer_columns > 0 { row_count += 1 }
	output_length := 0
	for row := 0; row < row_count; row += 1 {
		for column := 0; column < key_length; column += 1 {
			if row < column_lengths[column] { output[output_length] = columns[column][row]; output_length += 1 }
		}
	}
	return output_length
}

feed_value :: proc "contextless" (hash: u64, value: u64, width: int) -> u64 {
	result := hash
	bits := value
	for byte := 0; byte < width; byte += 1 { result = (result ^ (bits & 255)) * FNV_PRIME; bits >>= 8 }
	return result
}

@(export)
transposition_rust :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	mode, key_count_value := input[0], input[1]
	if (mode != 0 && mode != 1) || key_count_value < 1 || key_count_value > MAX_KEYS do return -1
	key_count := int(key_count_value)
	var keys: [MAX_KEYS][MAX_KEY_LENGTH]u8
	var key_lengths: [MAX_KEYS]int
	longest_key := 0
	cursor := 2
	for key_index := 0; key_index < key_count; key_index += 1 {
		if cursor >= int(length) do return -1
		key_length_value := input[cursor]
		cursor += 1
		if key_length_value < 1 || key_length_value > MAX_KEY_LENGTH do return -1
		key_length := int(key_length_value)
		if key_length > int(length) - cursor do return -1
		for i := 0; i < key_length; i += 1 {
			value := input[cursor+i]
			if !is_ascii_letter(value) do return -1
			ch := u8(value)
			if ch >= u8('a') && ch <= u8('z') { ch = ch - u8('a' - 'A') }
			keys[key_index][i] = ch
		}
		cursor += key_length
		key_lengths[key_index] = key_length
		if key_length > longest_key { longest_key = key_length }
	}
	if cursor >= int(length) do return -1
	message_length_value := input[cursor]
	cursor += 1
	if message_length_value < 1 || message_length_value > MAX_MESSAGE_LENGTH do return -1
	message_length := int(message_length_value)
	if message_length != int(length) - cursor do return -1
	var message: [MAX_MESSAGE_LENGTH]u8
	for i := 0; i < message_length; i += 1 { value := input[cursor+i]; if value < 0 || value > 127 do return -1; message[i] = u8(value) }

	var current: [MAX_OUTPUT_LENGTH]u8
	var filtered: [MAX_MESSAGE_LENGTH]u8
	var next: [MAX_OUTPUT_LENGTH]u8
	current_length := normalize(&message[0], message_length, &current[0])
	if current_length < longest_key do return -1
	for pass := 0; pass < key_count; pass += 1 {
		key_index := pass
		if mode == 1 { key_index = key_count - 1 - pass }
		filtered_length := normalize(&current[0], current_length, &filtered[0])
		var next_length: int
		if mode == 0 { next_length = encrypt_round(&filtered[0], filtered_length, &keys[key_index][0], key_lengths[key_index], &next[0]) }
		else { next_length = decrypt_round(&filtered[0], filtered_length, &keys[key_index][0], key_lengths[key_index], &next[0]) }
		for i := 0; i < next_length; i += 1 { current[i] = next[i] }
		current_length = next_length
	}
	hash := feed_value(FNV_OFFSET, u64(current_length), 8)
	for i := 0; i < current_length; i += 1 { hash = feed_value(hash, u64(current[i]), 4) }
	return i64(hash & LOW63_MASK)
}
