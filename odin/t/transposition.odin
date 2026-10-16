package transposition

import "core:c"

MAX_KEY :: 32
MAX_TEXT :: 512
MAX_INPUT :: 3 + MAX_KEY + MAX_TEXT
MAX_PADDED :: MAX_TEXT + MAX_KEY

hash_output :: proc(text: [^]u8, count: int) -> i64 {
	hash := u64(14695981039346656037)
	for shift in 0..<8 {
		byte := (u64(count) >> (shift * 8)) & 255
		hash = (hash ^ byte) * 1099511628211
	}
	for index in 0..<count {
		codepoint := u64(text[index])
		for shift in 0..<4 {
			byte := (codepoint >> (shift * 8)) & 255
			hash = (hash ^ byte) * 1099511628211
		}
	}
	return i64(hash & 0x7fffffffffffffff)
}

@(export)
transposition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	mode, key_length_value := input[0], input[1]
	if (mode != 0 && mode != 1) || key_length_value < 1 || key_length_value > MAX_KEY do return -1
	key_length := int(key_length_value)
	text_length_index := 2 + key_length
	if length <= c.size_t(text_length_index) do return -1
	text_length_value := input[text_length_index]
	if text_length_value < 1 || text_length_value > MAX_TEXT do return -1
	text_length := int(text_length_value)
	if length != c.size_t(text_length_index + 1 + text_length) do return -1

	var key: [MAX_KEY]u8
	var sorted: [MAX_KEY]u8
	for index in 0..<key_length {
		value := input[2 + index]
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) do return -1
		ch := u8(value)
		if ch >= 65 && ch <= 90 do ch += 32
		key[index], sorted[index] = ch, ch
	}
	for index in 1..<key_length {
		value := sorted[index]
		cursor := index
		for cursor > 0 && sorted[cursor - 1] > value {
			sorted[cursor] = sorted[cursor - 1]
			cursor -= 1
		}
		sorted[cursor] = value
	}
	var ranks: [MAX_KEY]int
	for index in 0..<key_length {
		first, duplicate := 0, 0
		for first < key_length && sorted[first] != key[index] do first += 1
		for prior in 0..<index { if key[prior] == key[index] do duplicate += 1 }
		ranks[index] = first + duplicate + 1
	}

	var text: [MAX_PADDED]u8
	for index in 0..<text_length {
		value := input[text_length_index + 1 + index]
		if value < 32 || value > 126 do return -1
		text[index] = u8(value)
	}
	if mode == 0 && text[text_length - 1] == 32 do return -1
	padding := key_length - text_length % key_length
	padded_length := text_length + padding
	for index in text_length..<padded_length do text[index] = 32

	var result: [MAX_PADDED]u8
	result_length := 0
	if mode == 0 {
		for start := 0; start < padded_length; start += key_length {
			var block: [MAX_KEY]u8
			for offset in 0..<key_length { block[ranks[offset] - 1] = text[start + offset] }
			for offset in 0..<key_length { result[result_length] = block[offset]; result_length += 1 }
		}
	} else {
		for start := 0; start < text_length; start += key_length {
			for offset in 0..<key_length { result[result_length] = text[start + ranks[offset] - 1]; result_length += 1 }
		}
		for result_length > 0 && result[result_length - 1] == 32 { result_length -= 1 }
	}
	return hash_output(&result[0], result_length)
}
