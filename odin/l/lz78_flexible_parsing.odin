package lz78_flexible_parsing

import "core:c"

MAX_TEXT :: 32
MAX_DICT :: MAX_TEXT + 1
MAX_OUTPUT :: 16 * MAX_TEXT

put_u64 :: proc(out: [^]u8, offset: int, value: u64) {
	for i := 0; i < 8; i += 1 { out[offset+i] = u8((value >> (8*i)) & 0xff) }
}
word_matches :: proc(words: [^][MAX_TEXT]u8, lengths: [^]int, id: int,
	text: [MAX_TEXT]u8, n, pos: int) -> bool {
	if pos + lengths[id] > n do return false
	for i := 0; i < lengths[id]; i += 1 { if words[id][i] != text[pos+i] do return false }
	return true
}
find_word :: proc(words: [^][MAX_TEXT]u8, lengths: [^]int, count: int,
	phrase: [MAX_TEXT]u8, size: int) -> int {
	for id := 1; id < count; id += 1 {
		if lengths[id] != size do continue
		same := true
		for i := 0; i < size; i += 1 { if words[id][i] != phrase[i] { same = false } }
		if same do return id
	}
	return count
}
longest_match :: proc(words: [^][MAX_TEXT]u8, lengths: [^]int, count: int,
	extra: [MAX_TEXT]u8, extra_len: int, has_extra: bool,
	text: [MAX_TEXT]u8, n, pos: int) -> int {
	best := 0
	for id := 1; id < count; id += 1 {
		if lengths[id] > best && word_matches(words, lengths, id, text, n, pos) { best = lengths[id] }
	}
	if has_extra && extra_len > best && pos + extra_len <= n {
		same := true
		for i := 0; i < extra_len; i += 1 { if extra[i] != text[pos+i] { same = false } }
		if same { best = extra_len }
	}
	return best
}

@(export)
lz78_flexible_parsing :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > 34 do return -1
	n0 := input[0]
	if n0 < 0 || n0 > MAX_TEXT || input_length != c.size_t(n0+1) do return -1
	n := int(n0)
	text: [MAX_TEXT]u8
	for i := 0; i < n; i += 1 {
		if input[i+1] < 32 || input[i+1] > 126 do return -1
		text[i] = u8(input[i+1])
	}
	words: [MAX_DICT][MAX_TEXT]u8
	lengths: [MAX_DICT]int
	parents: [MAX_TEXT]i64
	symbols: [MAX_TEXT]i64
	count, token_count, pos := 1, 0, 0
	for pos < n {
		final_id := count
		for id := 1; id < count; id += 1 {
			if lengths[id] == n-pos {
				same := true
				for i := 0; i < n-pos; i += 1 { if words[id][i] != text[pos+i] { same = false } }
				if same { final_id = id; break }
			}
		}
		if final_id != count { parents[token_count] = i64(final_id); symbols[token_count] = 0; token_count += 1; pos = n; break }
		have := false
		best_parent, best_len, best_next := 0, 0, 0
		best_symbol: u8 = 0
		best_new := false
		best_word: [MAX_TEXT]u8
		for parent := 0; parent < count; parent += 1 {
			if !word_matches(&words[0], &lengths[0], parent, text, n, pos) do continue
			prefix_len := lengths[parent]
			symbol_pos := pos + prefix_len
			if symbol_pos >= n do continue
			phrase_len := prefix_len + 1
			phrase: [MAX_TEXT]u8
			for i := 0; i < prefix_len; i += 1 { phrase[i] = words[parent][i] }
			phrase[prefix_len] = text[symbol_pos]
			is_new := find_word(&words[0], &lengths[0], count, phrase, phrase_len) == count
			next_pos := pos + phrase_len
			next_match := longest_match(&words[0], &lengths[0], count, phrase, phrase_len, is_new, text, n, next_pos)
			advancement := phrase_len + next_match
			if !have || advancement > best_next || (advancement == best_next && phrase_len > best_len) ||
				(advancement == best_next && phrase_len == best_len && parent < best_parent) {
				have = true; best_parent = parent; best_len = phrase_len; best_next = advancement
				best_symbol = text[symbol_pos]; best_new = is_new; best_word = phrase
			}
		}
		if !have do return -1
		parents[token_count] = i64(best_parent); symbols[token_count] = i64(best_symbol); token_count += 1
		if best_new { words[count] = best_word; lengths[count] = best_len; count += 1 }
		pos += best_len
	}
	output_bytes := token_count * 16
	staged: [MAX_OUTPUT]u8
	for i := 0; i < token_count; i += 1 { put_u64(&staged[0], 16*i, u64(parents[i])); put_u64(&staged[0], 16*i+8, u64(symbols[i])) }
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < output_bytes; i += 1 { output[i] = staged[i] }
	return i64(output_bytes)
}
