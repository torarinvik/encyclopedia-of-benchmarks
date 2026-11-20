package set_puzzle_find_sets

import "core:c"

Max_Cards :: 12
Max_Input_Words :: 14
Deck_Size :: 81

complement_code :: proc(a_raw, b_raw: i8) -> int {
	a, b := int(a_raw), int(b_raw)
	place, result := 1, 0
	for feature: int = 0; feature < 4; feature += 1 {
		digit_sum := (a / place) % 3 + (b / place) % 3
		result += ((3 - digit_sum % 3) % 3) * place
		place *= 3
	}
	return result
}

put_i64_le :: proc(value: i64, output: [^]u8, word: usize) {
	bits := transmute(u64)value
	for byte: usize = 0; byte < 8; byte += 1 {
		output[word * 8 + byte] = u8(bits >> u64(byte * 8))
	}
}

@(export)
set_puzzle_find_sets :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > Max_Input_Words do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > Max_Cards || length != c.size_t(raw_count + 1) do return -1

	index_by_code: [Deck_Size]i8
	code_by_index: [Max_Cards]i8
	for code: usize = 0; code < Deck_Size; code += 1 { index_by_code[code] = -1 }
	count := usize(raw_count)
	for i: usize = 0; i < count; i += 1 {
		code := input[i + 1]
		if code < 0 || code >= Deck_Size do return -1
		code_index := usize(code)
		if index_by_code[code_index] >= 0 do return -1
		index_by_code[code_index] = i8(i)
		code_by_index[i] = i8(code)
	}

	set_count: usize = 0
	for i: usize = 0; i < count; i += 1 {
		for j := i + 1; j < count; j += 1 {
			k := index_by_code[usize(complement_code(code_by_index[i], code_by_index[j]))]
			if k > i8(j) do set_count += 1
		}
	}
	output_bytes := (1 + 3 * set_count) * 8
	if output == nil || capacity < output_bytes do return -2

	put_i64_le(i64(set_count), output, 0)
	word: usize = 1
	for i: usize = 0; i < count; i += 1 {
		for j := i + 1; j < count; j += 1 {
			k := index_by_code[usize(complement_code(code_by_index[i], code_by_index[j]))]
			if k > i8(j) {
				put_i64_le(i64(i), output, word)
				put_i64_le(i64(j), output, word + 1)
				put_i64_le(i64(k), output, word + 2)
				word += 3
			}
		}
	}
	return i64(output_bytes)
}
