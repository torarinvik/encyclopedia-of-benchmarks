package lzw

import "core:c"

MAX_ITEMS :: 4096
MAX_CODES :: 4352
MAX_OUTPUT :: 65536
FNV_OFFSET :: u64(14695981039346656037)
FNV_PRIME :: u64(1099511628211)

hash_i64 :: proc(hash: u64, value: i64) -> u64 {
	result := hash
	bits := transmute(u64(value))
	for shift := 0; shift < 64; shift += 8 {
		result = (result ^ u64(u8(bits >> u64(shift)))) * FNV_PRIME
	}
	return result
}

hash_record :: proc(mode: i64, count: int, values: [^]i64) -> i64 {
	hash := hash_i64(FNV_OFFSET, mode)
	hash = hash_i64(hash, i64(count))
	for i := 0; i < count; i += 1 { hash = hash_i64(hash, values[i]) }
	return i64(hash & 0x7fffffffffffffff)
}

expand_code :: proc(code, dictionary_size: int, prefix: [^]i32, suffix: [^]u8, phrase: [^]u8) -> int {
	length := 0
	current := code
	for current >= 256 {
		if current >= dictionary_size || length >= MAX_CODES do return -1
		phrase[length] = suffix[current]
		length += 1
		if prefix[current] < 0 do return -1
		current = int(prefix[current])
	}
	if current < 0 || current > 255 || length >= MAX_CODES do return -1
	phrase[length] = u8(current)
	length += 1
	left, right := 0, length - 1
	for left < right {
		byte := phrase[left]; phrase[left] = phrase[right]; phrase[right] = byte
		left += 1; right -= 1
	}
	return length
}

@(export)
lzw :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_ITEMS + 2 do return -1
	mode, count64 := input[0], input[1]
	if (mode != 0 && mode != 1) || count64 < 0 || count64 > MAX_ITEMS || length != c.size_t(count64 + 2) do return -1
	count := int(count64)

	var prefix: [MAX_CODES]i32
	var next_sibling: [MAX_CODES]i32
	var first_child: [MAX_CODES]i32
	var suffix: [MAX_CODES]u8
	var first_symbol: [MAX_CODES]u8
	for i := 0; i < MAX_CODES; i += 1 {
		prefix[i] = -1; next_sibling[i] = -1; first_child[i] = -1
	}
	for code := 0; code < 256; code += 1 {
		suffix[code] = u8(code); first_symbol[code] = u8(code)
	}

	if mode == 0 {
		for i := 0; i < count; i += 1 { if input[2+i] < 0 || input[2+i] > 127 do return -1 }
		var codes: [MAX_ITEMS]i64
		code_count := 0
		if count > 0 {
			dictionary_size := 256
			current := int(input[2])
			for i := 1; i < count; i += 1 {
				byte := u8(input[2+i])
				match := first_child[current]
				for match >= 0 && suffix[match] != byte { match = next_sibling[match] }
				if match >= 0 {
					current = int(match)
				} else {
					codes[code_count] = i64(current); code_count += 1
					if dictionary_size >= MAX_CODES do return -1
					prefix[dictionary_size] = i32(current)
					suffix[dictionary_size] = byte
					first_symbol[dictionary_size] = first_symbol[current]
					next_sibling[dictionary_size] = first_child[current]
					first_child[current] = i32(dictionary_size)
					dictionary_size += 1
					current = int(byte)
				}
			}
			codes[code_count] = i64(current); code_count += 1
		}
		return hash_record(0, code_count, &codes[0])
	}

	for i := 0; i < count; i += 1 { if input[2+i] < 0 || input[2+i] >= MAX_CODES do return -1 }
	if count == 0 { return hash_record(1, 0, nil) }
	first_code := int(input[2])
	if first_code > 127 do return -1
	var decoded: [MAX_OUTPUT]u8
	var phrase: [MAX_CODES]u8
	decoded[0] = u8(first_code)
	decoded_length := 1
	dictionary_size := 256
	previous := first_code
	for i := 1; i < count; i += 1 {
		code := int(input[2+i])
		phrase_length := 0
		if code < dictionary_size {
			phrase_length = expand_code(code, dictionary_size, &prefix[0], &suffix[0], &phrase[0])
			if phrase_length < 0 do return -1
		} else if code == dictionary_size {
			phrase_length = expand_code(previous, dictionary_size, &prefix[0], &suffix[0], &phrase[0])
			if phrase_length < 0 || phrase_length >= MAX_CODES do return -1
			phrase[phrase_length] = first_symbol[previous]
			phrase_length += 1
		} else { return -1 }
		if decoded_length > MAX_OUTPUT - phrase_length do return -1
		for j := 0; j < phrase_length; j += 1 { if phrase[j] > 127 do return -1 }
		for j := 0; j < phrase_length; j += 1 { decoded[decoded_length] = phrase[j]; decoded_length += 1 }
		if dictionary_size >= MAX_CODES do return -1
		next_byte := first_symbol[previous]
		if code != dictionary_size { next_byte = first_symbol[code] }
		prefix[dictionary_size] = i32(previous)
		suffix[dictionary_size] = next_byte
		first_symbol[dictionary_size] = first_symbol[previous]
		dictionary_size += 1
		previous = code
	}
	hash := hash_i64(FNV_OFFSET, 1)
	hash = hash_i64(hash, i64(decoded_length))
	for i := 0; i < decoded_length; i += 1 { hash = hash_i64(hash, i64(decoded[i])) }
	return i64(hash & 0x7fffffffffffffff)
}
