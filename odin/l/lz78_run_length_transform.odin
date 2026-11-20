package lz78_run_length_transform

import "core:c"

Max_Text :: 32
Max_Input :: 34
Max_Trie_Nodes :: 33
Max_Tokens :: 32
Max_Output :: 776

put64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte_index := 0; byte_index < 8; byte_index += 1 {
		output[offset+byte_index] = u8((bits >> (byte_index*8)) & 0xff)
	}
}

@(export)
lz78_run_length_transform :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > Max_Input do return -1
	if input[0] < 0 || input[0] > Max_Text do return -1
	n := int(input[0])
	if input_length != c.size_t(n+1) do return -1
	for i := 0; i < n; i += 1 {
		if input[i+1] < 1 || input[i+1] > 3 do return -1
	}

	transformed: [Max_Text]i64
	transformed_length := 0
	position := 0
	for position < n {
		symbol := input[position+1]
		end := position+1
		for end < n && input[end+1] == symbol { end += 1 }
		run_length := end-position
		highest_bit := 0
		value := run_length
		for value > 1 { value >>= 1; highest_bit += 1 }
		bit := highest_bit
		for {
			if (run_length >> bit) & 1 != 0 { transformed[transformed_length] = symbol }
			else { transformed[transformed_length] = 0 }
			transformed_length += 1
			if bit == 0 { break }
			bit -= 1
		}
		position = end
	}

	children: [Max_Trie_Nodes][4]usize
	tokens: [Max_Tokens][3]i64
	token_count := 0
	text_position := 0
	next_phrase_id := 1
	for text_position < transformed_length {
		node := 0
		end := text_position
		for end < transformed_length {
			child := children[node][int(transformed[end])]
			if child == 0 { break }
			node = child
			end += 1
		}
		if end == transformed_length {
			if node != 0 {
				tokens[token_count] = {i64(node), 0, 1}
				token_count += 1
			}
			break
		}
		symbol := int(transformed[end])
		tokens[token_count] = {i64(node), i64(symbol), 0}
		token_count += 1
		children[node][symbol] = next_phrase_id
		next_phrase_id += 1
		text_position = end+1
	}

	output_bytes := 8+24*token_count
	staged: [Max_Output]u8
	put64(&staged[0], 0, i64(token_count))
	for token := 0; token < token_count; token += 1 {
		for field := 0; field < 3; field += 1 {
			put64(&staged[0], 8+24*token+8*field, tokens[token][field])
		}
	}
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < output_bytes; i += 1 { output[i] = staged[i] }
	return i64(output_bytes)
}
