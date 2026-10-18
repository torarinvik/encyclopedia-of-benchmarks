fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte_index in 0 .. 8 { output[offset + byte_index] = u8((bits >> (byte_index * 8)) & u64(0xff)) }
}

@[export: 'lz78_compress']
pub fn lz78_compress(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 66 { return -1 }
		if input[0] < 0 || input[0] > 64 { return -1 }
		text_length := int(input[0])
		if input_length != usize(1 + text_length) { return -1 }
		for index in 0 .. text_length {
			character := input[index + 1]
			if character < 32 || character > 126 { return -1 }
		}

		mut edge_parent := [64]i64{}
		mut edge_character := [64]i64{}
		mut dictionary_size := 0
		mut token_indices := [64]i64{}
		mut token_characters := [64]i64{}
		mut token_count := 0
		mut current_index := i64(0)
		for index in 0 .. text_length {
			character := input[index + 1]
			mut found := -1
			for edge in 0 .. dictionary_size {
				if edge_parent[edge] == current_index && edge_character[edge] == character { found = edge; break }
			}
			if found >= 0 {
				current_index = i64(found + 1)
			} else {
				token_indices[token_count] = current_index
				token_characters[token_count] = character
				token_count++
				edge_parent[dictionary_size] = current_index
				edge_character[dictionary_size] = character
				dictionary_size++
				current_index = 0
			}
		}
		if current_index != 0 {
			token_indices[token_count] = current_index
			token_characters[token_count] = 0
			token_count++
		}

		output_bytes := 16 * token_count
		mut staged := [1024]u8{}
		for token in 0 .. token_count {
			put_i64_le(mut staged[0], 16 * token, token_indices[token])
			put_i64_le(mut staged[0], 16 * token + 8, token_characters[token])
		}
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
