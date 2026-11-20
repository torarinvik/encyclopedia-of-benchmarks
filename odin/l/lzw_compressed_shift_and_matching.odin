package lzw_compressed_shift_and_matching

import "core:c"

MAX_ALPHABET :: 16
MAX_PATTERN :: 32
MAX_CODES :: 32
MAX_DICTIONARY :: 47
MAX_EXPANDED :: 528
MAX_INPUT :: 67
MAX_OUTPUT_BYTES :: 4232

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
lzw_compressed_shift_and_matching :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	alphabet_raw, pattern_raw, code_count_raw := input[0], input[1], input[2]
	if alphabet_raw < 1 || alphabet_raw > MAX_ALPHABET || pattern_raw < 1 || pattern_raw > MAX_PATTERN || code_count_raw < 0 || code_count_raw > MAX_CODES do return -1
	alphabet_size := int(alphabet_raw)
	pattern_length := int(pattern_raw)
	code_count := int(code_count_raw)
	if int(length) != 3+pattern_length+code_count do return -1
	symbol_mask: [MAX_ALPHABET]u32 = {}
	for i := 0; i < pattern_length; i += 1 {
		symbol := input[3+i]
		if symbol < 0 || symbol >= alphabet_raw do return -1
		symbol_mask[int(symbol)] |= u32(1) << i
	}
	if code_count > 0 && (input[3+pattern_length] < 0 || input[3+pattern_length] >= alphabet_raw) do return -1

	phrase_length: [MAX_DICTIONARY]int = {}
	first_symbol: [MAX_DICTIONARY]u8 = {}
	phrase_mask, crossing_mask: [MAX_DICTIONARY]u32 = {}, {}
	ends_match: [MAX_DICTIONARY]bool = {}
	previous_match: [MAX_DICTIONARY]int = {}
	top_bit := u32(1) << (pattern_length-1)
	for symbol := 0; symbol < alphabet_size; symbol += 1 {
		phrase_length[symbol] = 1
		first_symbol[symbol] = u8(symbol)
		phrase_mask[symbol] = symbol_mask[symbol]
		if pattern_length > 1 && (phrase_mask[symbol]&top_bit) != 0 { crossing_mask[symbol] = u32(1) << (pattern_length-2) }
		ends_match[symbol] = pattern_length == 1 && (phrase_mask[symbol]&top_bit) != 0
		previous_match[symbol] = -1
	}

	words: [1+MAX_EXPANDED]i64 = {}
	occurrence_count, node_count, text_offset := 0, alphabet_size, 0
	state: u32 = 0
	previous_code := -1
	for token := 0; token < code_count; token += 1 {
		code_raw := input[3+pattern_length+token]
		current_code := 0
		if previous_code < 0 { current_code = int(code_raw) }
		else {
			if code_raw < 0 || code_raw > i64(node_count) do return -1
			appended: u8
			if code_raw == i64(node_count) { appended = first_symbol[previous_code]; current_code = node_count }
			else { current_code = int(code_raw); appended = first_symbol[current_code] }
			if node_count >= MAX_DICTIONARY do return -1
			node := node_count
			node_count += 1
			phrase_length[node] = phrase_length[previous_code]+1
			first_symbol[node] = first_symbol[previous_code]
			phrase_mask[node] = ((phrase_mask[previous_code]<<1)|1) & symbol_mask[int(appended)]
			crossing_mask[node] = crossing_mask[previous_code]
			if phrase_length[node] < pattern_length && (phrase_mask[node]&top_bit) != 0 {
				crossing_mask[node] |= u32(1) << (pattern_length-phrase_length[node]-1)
			}
			ends_match[node] = phrase_length[node] >= pattern_length && (phrase_mask[node]&top_bit) != 0
			if ends_match[previous_code] { previous_match[node] = previous_code } else { previous_match[node] = previous_match[previous_code] }
		}

		crossing := state & crossing_mask[current_code]
		for crossing != 0 {
			highest := 0
			bits := crossing
			for (bits>>1) != 0 { bits >>= 1; highest += 1 }
			words[1+occurrence_count] = i64(text_offset-highest-1)
			occurrence_count += 1
			crossing &= ~(u32(1)<<highest)
		}
		internal_nodes: [MAX_DICTIONARY]int = {}
		internal_count := 0
		node := current_code
		if !ends_match[current_code] { node = previous_match[current_code] }
		for node >= 0 { internal_nodes[internal_count] = node; internal_count += 1; node = previous_match[node] }
		for internal_count > 0 {
			internal_count -= 1
			node = internal_nodes[internal_count]
			words[1+occurrence_count] = i64(text_offset+phrase_length[node]-pattern_length)
			occurrence_count += 1
		}

		current_length := phrase_length[current_code]
		shifted: u32 = 0
		if current_length < pattern_length { shifted = state << current_length }
		fresh: u32
		if current_length >= pattern_length {
			if pattern_length == 32 { fresh = 0xffffffff } else { fresh = (u32(1)<<pattern_length)-1 }
		} else { fresh = (u32(1)<<current_length)-1 }
		state = (shifted|fresh) & phrase_mask[current_code]
		text_offset += current_length
		previous_code = current_code
	}
	words[0] = i64(occurrence_count)
	output_bytes := 8*(1+occurrence_count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for word := 0; word < 1+occurrence_count; word += 1 { store_i64_le(&staged[0], 8*word, words[word]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
