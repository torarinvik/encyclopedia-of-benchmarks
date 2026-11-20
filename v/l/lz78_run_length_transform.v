fn lz78rt_put(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte_index in 0 .. 8 { output[offset + byte_index] = u8((bits >> (byte_index * 8)) & u64(255)) }
}

@[export: 'lz78_run_length_transform']
pub fn lz78_run_length_transform(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 34 { return -1 }
		if input[0] < 0 || input[0] > 32 { return -1 }
		n := int(input[0])
		if input_length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 1 || input[i + 1] > 3 { return -1 } }

		mut transformed := [32]i64{}
		mut transformed_length := 0
		mut position := 0
		for position < n {
			symbol := input[position + 1]
			mut end := position + 1
			for end < n && input[end + 1] == symbol { end++ }
			run_length := end - position
			mut highest_bit := 0
			mut value := run_length
			for value > 1 { value >>= 1; highest_bit++ }
			for bit := highest_bit; bit >= 0; bit-- {
				transformed[transformed_length] = if (run_length >> bit) & 1 != 0 { symbol } else { i64(0) }
				transformed_length++
			}
			position = end
		}

		mut children := [33][4]int{}
		mut tokens := [32][3]i64{}
		mut token_count := 0
		mut text_position := 0
		mut next_phrase_id := 1
		for text_position < transformed_length {
			mut node := 0
			mut end := text_position
			for end < transformed_length {
				child := children[node][int(transformed[end])]
				if child == 0 { break }
				node = child
				end++
			}
			if end == transformed_length {
				if node != 0 {
					tokens[token_count][0] = i64(node)
					tokens[token_count][1] = 0
					tokens[token_count][2] = 1
					token_count++
				}
				break
			}
			symbol := int(transformed[end])
			tokens[token_count][0] = i64(node)
			tokens[token_count][1] = i64(symbol)
			tokens[token_count][2] = 0
			token_count++
			children[node][symbol] = next_phrase_id
			next_phrase_id++
			text_position = end + 1
		}

		output_bytes := 8 + 24 * token_count
		mut staged := [776]u8{}
		lz78rt_put(mut staged[0], 0, i64(token_count))
		for token in 0 .. token_count {
			for field in 0 .. 3 { lz78rt_put(mut staged[0], 8 + 24 * token + 8 * field, tokens[token][field]) }
		}
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. output_bytes { output[i] = staged[i] }
		return i64(output_bytes)
	}
}
