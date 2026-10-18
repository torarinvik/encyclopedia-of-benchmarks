package memoize

import "core:c"

MAX_INPUT_LENGTH :: 259
MAX_ARITY :: 4
MAX_CALLS :: 64
MAX_OUTPUT_BYTES :: 520
BASE :: i64(201)

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte_index := 0; byte_index < 8; byte_index += 1 {
		output[offset+byte_index] = u8((bits >> (byte_index*8)) & 0xff)
	}
}

@(export)
memoize :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_ARITY || input[1] < 0 || input[1] > MAX_CALLS do return -1
	arity, call_count := int(input[0]), int(input[1])
	if int(input_length) != 2 + arity*call_count do return -1
	for index := 0; index < arity*call_count; index += 1 {
		value := input[2+index]
		if value < -100 || value > 100 do return -1
	}

	keys: [MAX_CALLS][MAX_ARITY]i64
	key_results: [MAX_CALLS]i64
	key_count := 0
	results: [MAX_CALLS+1]i64
	for call_index := 0; call_index < call_count; call_index += 1 {
		start := 2 + call_index*arity
		key: [MAX_ARITY]i64
		encoded := i64(0)
		for argument_index := 0; argument_index < arity; argument_index += 1 {
			value := input[start+argument_index]
			key[argument_index] = value
			encoded = encoded*BASE + value + 100
		}
		found := -1
		for previous := 0; previous < key_count; previous += 1 {
			equal := true
			for argument_index := 0; argument_index < arity; argument_index += 1 {
				if keys[previous][argument_index] != key[argument_index] { equal = false }
			}
			if equal { found = previous; break }
		}
		if found >= 0 {
			results[call_index] = key_results[found]
		} else {
			keys[key_count] = key
			key_results[key_count] = encoded
			key_count += 1
			results[call_index] = encoded
		}
	}
	results[call_count] = i64(key_count)

	output_bytes := 8*(call_count+1)
	staged: [MAX_OUTPUT_BYTES]u8
	for index := 0; index <= call_count; index += 1 { put_i64_le(&staged[0], index*8, results[index]) }
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
