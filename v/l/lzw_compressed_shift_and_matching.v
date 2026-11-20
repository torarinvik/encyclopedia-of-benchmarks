module lzw_compressed_shift_and_matching

import core.c

const max_alphabet = 16
const max_pattern = 32
const max_codes = 32
const max_dictionary = 47
const max_expanded = 528
const max_input = 67
const max_output_bytes = 4232

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'lzw_compressed_shift_and_matching']
pub fn lzw_compressed_shift_and_matching(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		alphabet_raw := input[0]
		pattern_raw := input[1]
		code_count_raw := input[2]
		if alphabet_raw < 1 || alphabet_raw > max_alphabet || pattern_raw < 1 || pattern_raw > max_pattern || code_count_raw < 0 || code_count_raw > max_codes { return -1 }
		alphabet_size := int(alphabet_raw)
		pattern_length := int(pattern_raw)
		code_count := int(code_count_raw)
		if int(length) != 3 + pattern_length + code_count { return -1 }
		mut symbol_mask := [max_alphabet]u32{}
		for i in 0 .. pattern_length {
			symbol := input[3 + i]
			if symbol < 0 || symbol >= alphabet_raw { return -1 }
			symbol_mask[int(symbol)] |= u32(1) << i
		}
		if code_count > 0 && (input[3 + pattern_length] < 0 || input[3 + pattern_length] >= alphabet_raw) { return -1 }

		mut phrase_length := [max_dictionary]int{}
		mut first_symbol := [max_dictionary]u8{}
		mut phrase_mask := [max_dictionary]u32{}
		mut crossing_mask := [max_dictionary]u32{}
		mut ends_match := [max_dictionary]bool{}
		mut previous_match := [max_dictionary]int{}
		top_bit := u32(1) << (pattern_length - 1)
		for symbol in 0 .. alphabet_size {
			phrase_length[symbol] = 1
			first_symbol[symbol] = u8(symbol)
			phrase_mask[symbol] = symbol_mask[symbol]
			if pattern_length > 1 && (phrase_mask[symbol] & top_bit) != 0 { crossing_mask[symbol] = u32(1) << (pattern_length - 2) }
			ends_match[symbol] = pattern_length == 1 && (phrase_mask[symbol] & top_bit) != 0
			previous_match[symbol] = -1
		}

		mut words := [1 + max_expanded]i64{}
		mut occurrence_count := 0
		mut node_count := alphabet_size
		mut text_offset := 0
		mut state := u32(0)
		mut previous_code := -1
		for token in 0 .. code_count {
			code_raw := input[3 + pattern_length + token]
			mut current_code := 0
			if previous_code < 0 { current_code = int(code_raw) }
			else {
				if code_raw < 0 || code_raw > i64(node_count) { return -1 }
				mut appended := u8(0)
				if code_raw == i64(node_count) {
					appended = first_symbol[previous_code]
					current_code = node_count
				} else {
					current_code = int(code_raw)
					appended = first_symbol[current_code]
				}
				if node_count >= max_dictionary { return -1 }
				node := node_count
				node_count++
				phrase_length[node] = phrase_length[previous_code] + 1
				first_symbol[node] = first_symbol[previous_code]
				phrase_mask[node] = ((phrase_mask[previous_code] << 1) | 1) & symbol_mask[int(appended)]
				crossing_mask[node] = crossing_mask[previous_code]
				if phrase_length[node] < pattern_length && (phrase_mask[node] & top_bit) != 0 {
					crossing_mask[node] |= u32(1) << (pattern_length - phrase_length[node] - 1)
				}
				ends_match[node] = phrase_length[node] >= pattern_length && (phrase_mask[node] & top_bit) != 0
				previous_match[node] = if ends_match[previous_code] { previous_code } else { previous_match[previous_code] }
			}

			mut crossing := state & crossing_mask[current_code]
			for crossing != 0 {
				mut highest := 0
				mut bits := crossing
				for (bits >> 1) != 0 { bits >>= 1; highest++ }
				words[1 + occurrence_count] = i64(text_offset - highest - 1)
				occurrence_count++
				crossing &= ~(u32(1) << highest)
			}
			mut internal_nodes := [max_dictionary]int{}
			mut internal_count := 0
			mut node := if ends_match[current_code] { current_code } else { previous_match[current_code] }
			for node >= 0 {
				internal_nodes[internal_count] = node
				internal_count++
				node = previous_match[node]
			}
			for internal_count > 0 {
				internal_count--
				node = internal_nodes[internal_count]
				words[1 + occurrence_count] = i64(text_offset + phrase_length[node] - pattern_length)
				occurrence_count++
			}

			current_length := phrase_length[current_code]
			mut shifted := u32(0)
			if current_length < pattern_length { shifted = state << current_length }
			mut fresh := u32(0)
			if current_length >= pattern_length {
				fresh = if pattern_length == 32 { u32(0xffffffff) } else { (u32(1) << pattern_length) - 1 }
			} else { fresh = (u32(1) << current_length) - 1 }
			state = (shifted | fresh) & phrase_mask[current_code]
			text_offset += current_length
			previous_code = current_code
		}
		words[0] = i64(occurrence_count)
		output_bytes := 8 * (1 + occurrence_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for word in 0 .. 1 + occurrence_count { store_i64_le(mut staged[0], 8 * word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
