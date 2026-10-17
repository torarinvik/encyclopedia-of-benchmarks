package lfu

import "core:c"

MIN_CAPACITY :: 2
MAX_CAPACITY :: 16
MAX_OPERATIONS :: 32
MAX_INPUT_LENGTH :: 2 + 3 * MAX_OPERATIONS
MAX_OUTPUT_WORDS :: 3 * MAX_OPERATIONS

move_to_front :: proc(keys: ^[MAX_CAPACITY]i32, values: ^[MAX_CAPACITY]i32, index: int) {
	key, value := keys[index], values[index]
	for i := index; i > 0; i -= 1 {
		keys[i], values[i] = keys[i-1], values[i-1]
	}
	keys[0], values[0] = key, value
}

append :: proc(words: ^[MAX_OUTPUT_WORDS]i64, count: ^c.size_t, value: i64) {
	words[count^] = value
	count^ += 1
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> u64(8*byte)) & 255)
	}
}

@(export)
lfu :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < MIN_CAPACITY || input[0] > MAX_CAPACITY ||
		input[1] < 0 || input[1] > MAX_OPERATIONS do return -1

	cache_capacity := int(input[0])
	operation_count := int(input[1])
	var keys: [MAX_CAPACITY]i32
	var values: [MAX_CAPACITY]i32
	size := 0
	var words: [MAX_OUTPUT_WORDS]i64
	word_count: c.size_t = 0
	position: c.size_t = 2

	for _ in 0..<operation_count {
		if position >= length do return -1
		opcode := input[position]
		position += 1
		if opcode == 0 {
			if position + 1 >= length do return -1
			key_arg, value_arg := input[position], input[position+1]
			position += 2
			if key_arg < -2147483648 || key_arg > 2147483647 ||
				value_arg < -2147483648 || value_arg > 2147483647 do return -1
			key := i32(key_arg)
			index := 0
			for index < size && keys[index] != key { index += 1 }
			if index < size {
				// The pinned Put mutates a copied item; the old value remains.
				move_to_front(&keys, &values, index)
			} else {
				if size == cache_capacity do size -= 1
				for i := size; i > 0; i -= 1 {
					keys[i], values[i] = keys[i-1], values[i-1]
				}
				keys[0], values[0] = key, i32(value_arg)
				size += 1
			}
			append(&words, &word_count, 0)
		} else if opcode == 1 {
			if position >= length do return -1
			key_arg := input[position]
			position += 1
			if key_arg < -2147483648 || key_arg > 2147483647 do return -1
			key := i32(key_arg)
			index := 0
			for index < size && keys[index] != key { index += 1 }
			append(&words, &word_count, 1)
			if index == size {
				append(&words, &word_count, 1)
				append(&words, &word_count, 0)
			} else {
				value := values[index]
				move_to_front(&keys, &values, index)
				append(&words, &word_count, 0)
				append(&words, &word_count, i64(value))
			}
		} else {
			return -1
		}
	}
	if position != length || word_count > MAX_OUTPUT_WORDS do return -1
	output_length := word_count * 8
	if output == nil || output_capacity < output_length do return -2
	for i: c.size_t = 0; i < word_count; i += 1 {
		put_i64_le(output, int(i*8), words[i])
	}
	return i64(output_length)
}
