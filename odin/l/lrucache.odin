package lrucache

import "core:c"

MAX_CAPACITY :: 16
MAX_OPERATIONS :: 32
MAX_INPUT_LENGTH :: 99
MAX_OUTPUT_WORDS :: 130

@(export)
lrucache :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH do return -1
	capacity_value := input[0]
	operation_count_value := input[1]
	if capacity_value < 2 || capacity_value > MAX_CAPACITY ||
		operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	capacity := int(capacity_value)
	operation_count := int(operation_count_value)
	if int(input_length) != 2 + 3 * operation_count do return -1

	keys: [MAX_CAPACITY]i64
	cached_values: [MAX_CAPACITY]i64
	seen_put_keys: [MAX_OPERATIONS]i64
	operation_records: [3*MAX_OPERATIONS]i64
	used := 0
	seen_count := 0

	for operation in 0..<operation_count {
		opcode := input[2+3*operation]
		key := input[3+3*operation]
		value := input[4+3*operation]
		if opcode != 0 && opcode != 1 do return -1
		if key < 0 || key > 1000000 do return -1
		returned_value := i64(-1)
		evicted_key := i64(-1)
		position := 0
		for position < used && keys[position] != key { position += 1 }

		if opcode == 0 {
			if value < 0 || value > 1000000 do return -1
			for prior in 0..<seen_count { if seen_put_keys[prior] == key do return -1 }
			seen_put_keys[seen_count] = key
			seen_count += 1
			if used == capacity {
				evicted_key = keys[0]
				for index in 1..<used {
					keys[index-1] = keys[index]
					cached_values[index-1] = cached_values[index]
				}
				used -= 1
			}
			keys[used] = key
			cached_values[used] = value
			used += 1
		} else {
			if value != 0 || position == used do return -1
			returned_value = cached_values[position]
			for index in position+1..<used {
				keys[index-1] = keys[index]
				cached_values[index-1] = cached_values[index]
			}
			keys[used-1] = key
			cached_values[used-1] = returned_value
		}
		operation_records[3*operation] = opcode
		operation_records[3*operation+1] = returned_value
		operation_records[3*operation+2] = evicted_key
	}

	fields: [MAX_OUTPUT_WORDS]i64
	word_count := 0
	fields[word_count] = operation_count_value
	word_count += 1
	for index in 0..<3*operation_count {
		fields[word_count] = operation_records[index]
		word_count += 1
	}
	fields[word_count] = i64(used)
	word_count += 1
	for index := used-1; index >= 0; index -= 1 {
		fields[word_count] = keys[index]
		fields[word_count+1] = cached_values[index]
		word_count += 2
	}

	output_bytes := word_count * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index in 0..<word_count {
		bits := u64(fields[index])
		for byte in 0..<8 {
			output[index*8+byte] = u8(bits & 0xff)
			bits >>= 8
		}
	}
	return i64(output_bytes)
}
