package lz78

import "core:c"

MAX_INPUT_LENGTH :: 66
MAX_TEXT_LENGTH :: 64
MAX_OUTPUT_BYTES :: 1024

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte_index := 0; byte_index < 8; byte_index += 1 {
		output[offset+byte_index] = u8((bits >> (byte_index*8)) & 0xff)
	}
}

@(export)
lz78_compress :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_TEXT_LENGTH do return -1
	text_length := int(input[0])
	if int(input_length) != 1 + text_length do return -1
	for index := 0; index < text_length; index += 1 {
		character := input[index+1]
		if character < 32 || character > 126 do return -1
	}

	edge_parent: [MAX_TEXT_LENGTH]i64
	edge_character: [MAX_TEXT_LENGTH]i64
	dictionary_size := 0
	token_indices: [MAX_TEXT_LENGTH]i64
	token_characters: [MAX_TEXT_LENGTH]i64
	token_count := 0
	current_index := i64(0)
	for index := 0; index < text_length; index += 1 {
		character := input[index+1]
		found := -1
		for edge := 0; edge < dictionary_size; edge += 1 {
			if edge_parent[edge] == current_index && edge_character[edge] == character { found = edge; break }
		}
		if found >= 0 {
			current_index = i64(found+1)
		} else {
			token_indices[token_count] = current_index
			token_characters[token_count] = character
			token_count += 1
			edge_parent[dictionary_size] = current_index
			edge_character[dictionary_size] = character
			dictionary_size += 1
			current_index = 0
		}
	}
	if current_index != 0 {
		token_indices[token_count] = current_index
		token_characters[token_count] = 0
		token_count += 1
	}

	output_bytes := 16 * token_count
	staged: [MAX_OUTPUT_BYTES]u8
	for token := 0; token < token_count; token += 1 {
		put_i64_le(&staged[0], 16*token, token_indices[token])
		put_i64_le(&staged[0], 16*token+8, token_characters[token])
	}
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
