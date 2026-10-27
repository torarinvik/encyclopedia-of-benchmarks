fn put_u64(mut output &u8, offset int, value u64) {
	for i in 0 .. 8 { output[offset + i] = u8((value >> (i * 8)) & u64(255)) }
}

@[export: 'lz78_flexible_parsing']
pub fn lz78_flexible_parsing(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 34 { return -1 }
		if input[0] < 0 || input[0] > 32 { return -1 }
		n := int(input[0])
		if input_length != usize(n + 1) { return -1 }
		mut text := [32]u8{}
		for i in 0 .. n {
			if input[i + 1] < 32 || input[i + 1] > 126 { return -1 }
			text[i] = u8(input[i + 1])
		}
		mut words := [33][32]u8{}
		mut lengths := [33]int{}
		mut parents := [32]i64{}
		mut symbols := [32]i64{}
		mut count, mut token_count, mut pos := 1, 0, 0
		for pos < n {
			mut final_id := count
			for id in 1 .. count {
				if lengths[id] == n - pos {
					mut same := true
					for i in 0 .. n - pos { if words[id][i] != text[pos + i] { same = false } }
					if same { final_id = id; break }
				}
			}
			if final_id != count { parents[token_count] = i64(final_id); symbols[token_count] = 0; token_count++; pos = n; break }
			mut have := false
			mut best_parent, mut best_len, mut best_next := 0, 0, 0
			mut best_symbol := u8(0)
			mut best_new := false
			mut best_word := [32]u8{}
			for parent in 0 .. count {
				prefix_len := lengths[parent]
				if pos + prefix_len > n { continue }
				mut prefix_match := true
				for i in 0 .. prefix_len { if words[parent][i] != text[pos + i] { prefix_match = false } }
				if !prefix_match { continue }
				symbol_pos := pos + prefix_len
				if symbol_pos >= n { continue }
				phrase_len := prefix_len + 1
				mut phrase := [32]u8{}
				for i in 0 .. prefix_len { phrase[i] = words[parent][i] }
				phrase[prefix_len] = text[symbol_pos]
				mut phrase_id := count
				for id in 1 .. count {
					if lengths[id] == phrase_len {
						mut same := true
						for i in 0 .. phrase_len { if words[id][i] != phrase[i] { same = false } }
						if same { phrase_id = id; break }
					}
				}
				is_new := phrase_id == count
				next_pos := pos + phrase_len
				mut next_match := 0
				for id in 1 .. count {
					match_len := lengths[id]
					if match_len > next_match && next_pos + match_len <= n {
						mut same := true
						for i in 0 .. match_len { if words[id][i] != text[next_pos + i] { same = false } }
						if same { next_match = match_len }
					}
				}
				if is_new && phrase_len > next_match && next_pos + phrase_len <= n {
					mut same := true
					for i in 0 .. phrase_len { if phrase[i] != text[next_pos + i] { same = false } }
					if same { next_match = phrase_len }
				}
				advancement := phrase_len + next_match
				if !have || advancement > best_next || (advancement == best_next && phrase_len > best_len) ||
					(advancement == best_next && phrase_len == best_len && parent < best_parent) {
					have = true; best_parent = parent; best_len = phrase_len; best_next = advancement
					best_symbol = text[symbol_pos]; best_new = is_new; best_word = phrase
				}
			}
			if !have { return -1 }
			parents[token_count] = i64(best_parent); symbols[token_count] = i64(best_symbol); token_count++
			if best_new { words[count] = best_word; lengths[count] = best_len; count++ }
			pos += best_len
		}
		output_bytes := 16 * token_count
		mut staged := [512]u8{}
		for i in 0 .. token_count { put_u64(mut staged[0], 16*i, u64(parents[i])); put_u64(mut staged[0], 16*i+8, u64(symbols[i])) }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. output_bytes { output[i] = staged[i] }
		return i64(output_bytes)
	}
}
