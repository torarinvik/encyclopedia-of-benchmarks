package dynamic_array

import "core:c"

MAX_OPERATIONS :: 128
MAX_ELEMENTS :: 64
MAX_INPUT_LENGTH :: 1 + 3 * MAX_OPERATIONS

write_i64_le :: proc "contextless" (output: [^]u8, word_index: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[word_index * 8 + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
dynamic_array :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	operation_count_value := input[0]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1

	first: [MAX_ELEMENTS]i64 = {}
	second: [MAX_ELEMENTS]i64 = {}
	query_results: [MAX_OPERATIONS]i64 = {}
	active_first := true
	size := 0
	capacity := 16
	cursor := 1
	query_count := 0
	input_length := int(length)

	for operation_index := 0; operation_index < int(operation_count_value); operation_index += 1 {
		if cursor >= input_length do return -1
		operation := input[cursor]
		cursor += 1
		if operation == 0 {
			if cursor >= input_length || size >= MAX_ELEMENTS do return -1
			value := input[cursor]
			cursor += 1
			if size == capacity {
				if active_first {
					for index := 0; index < size; index += 1 { second[index] = first[index] }
					active_first = false
				} else {
					for index := 0; index < size; index += 1 { first[index] = second[index] }
					active_first = true
				}
				capacity *= 2
			}
			if active_first { first[size] = value } else { second[size] = value }
			size += 1
		} else if operation == 1 {
			if cursor + 1 >= input_length do return -1
			index_value := input[cursor]
			value := input[cursor + 1]
			cursor += 2
			if index_value < 0 || index_value >= i64(size) do return -1
			index := int(index_value)
			if active_first { first[index] = value } else { second[index] = value }
		} else if operation == 2 {
			if cursor >= input_length || query_count >= MAX_OPERATIONS do return -1
			index_value := input[cursor]
			cursor += 1
			if index_value < 0 || index_value >= i64(size) do return -1
			index := int(index_value)
			if active_first { query_results[query_count] = first[index] } else { query_results[query_count] = second[index] }
			query_count += 1
		} else if operation == 3 {
			if query_count >= MAX_OPERATIONS do return -1
			query_results[query_count] = i64(size)
			query_count += 1
		} else {
			return -1
		}
	}
	if cursor != input_length do return -1

	output_words := 2 + query_count + size
	output_bytes := c.size_t(output_words * 8)
	if output == nil || output_capacity < output_bytes do return -2
	write_i64_le(output, 0, i64(query_count))
	for index := 0; index < query_count; index += 1 {
		write_i64_le(output, index + 1, query_results[index])
	}
	write_i64_le(output, query_count + 1, i64(size))
	for index := 0; index < size; index += 1 {
		value := first[index]
		if !active_first { value = second[index] }
		write_i64_le(output, query_count + 2 + index, value)
	}
	return i64(output_words)
}
