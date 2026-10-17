@[export: 'suffix_trie_search']
pub fn suffix_trie_search(input &i64, input_length usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 83 { return -1 }
		text_length_value := input[0]
		pattern_length_value := input[1]
		if text_length_value < 0 || text_length_value > 64 ||
			pattern_length_value < 0 || pattern_length_value > 16 { return -1 }
		text_length := int(text_length_value)
		pattern_length := int(pattern_length_value)
		if input_length != usize(2+text_length+pattern_length) { return -1 }
		mut text := [64]u8{}
		mut pattern := [16]u8{}
		for i in 0 .. text_length {
			code := input[2+i]
			if code < 0 || code > 127 { return -1 }
			text[i] = u8(code)
		}
		for i in 0 .. pattern_length {
			code := input[2+text_length+i]
			if code < 0 || code > 127 { return -1 }
			pattern[i] = u8(code)
		}

		mut first_child := [2081]int{}
		mut next_sibling := [2081]int{}
		mut edge_code := [2081]u8{}
		for i in 0 .. 2081 {
			first_child[i] = -1
			next_sibling[i] = -1
		}
		mut node_count := 1
		for start in 0 .. text_length {
			mut parent := 0
			for position in start .. text_length {
				code := text[position]
				mut child := first_child[parent]
				for child >= 0 && edge_code[child] != code { child = next_sibling[child] }
				if child < 0 {
					child = node_count
					node_count++
					edge_code[child] = code
					next_sibling[child] = first_child[parent]
					first_child[parent] = child
				}
				parent = child
			}
		}
		mut parent := 0
		for i in 0 .. pattern_length {
			mut child := first_child[parent]
			for child >= 0 && edge_code[child] != pattern[i] { child = next_sibling[child] }
			if child < 0 { return 0 }
			parent = child
		}
		return 1
	}
}
