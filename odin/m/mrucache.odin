package mrucache

import "core:c"

MAX_OPERATIONS :: 128
MAX_CAPACITY :: 16
MAX_INPUT_LENGTH :: 387
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_byte :: proc(hash: u64, byte: u8) -> u64 {
	return (hash ^ u64(byte)) * FNV_PRIME
}

hash_responses :: proc(responses: [^]i32, count: int) -> i64 {
	hash := FNV_OFFSET
	hash = hash_byte(hash, u8(count))
	hash = hash_byte(hash, u8(count >> 8))
	for index := 0; index < count; index += 1 {
		bits := transmute(u32(responses[index]))
		for shift := 0; shift < 32; shift += 8 { hash = hash_byte(hash, u8(bits >> u32(shift))) }
	}
	return i64(hash & 0x7fffffffffffffff)
}

mrucache :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	capacity64, operation_count64 := input[0], input[1]
	if capacity64 < 1 || capacity64 > MAX_CAPACITY || operation_count64 < 0 || operation_count64 > MAX_OPERATIONS
		|| length != c.size_t(2 + 3 * operation_count64) do return -1
	capacity, operation_count := int(capacity64), int(operation_count64)
	var keys: [MAX_CAPACITY]i32
	var values: [MAX_CAPACITY]i32
	var responses: [MAX_OPERATIONS]i32
	cache_count, response_count := 0, 0

	for step := 0; step < operation_count; step += 1 {
		operation, key64, value64 := input[2+3*step], input[3+3*step], input[4+3*step]
		if operation < 0 || operation > 1 || key64 < -2147483648 || key64 > 2147483647
			|| value64 < -2147483648 || value64 > 2147483647 do return -1
		key, value := i32(key64), i32(value64)
		position := 0
		for position < cache_count && keys[position] != key { position += 1 }

		if operation == 0 {
			if value < 0 || value > 1_000_000 do return -1
			if position < cache_count {
				for index := position; index+1 < cache_count; index += 1 {
					keys[index] = keys[index+1]
					values[index] = values[index+1]
				}
				keys[cache_count-1], values[cache_count-1] = key, value
			} else {
				if cache_count == capacity { cache_count -= 1 }
				keys[cache_count], values[cache_count] = key, value
				cache_count += 1
			}
		} else if position == cache_count {
			responses[response_count] = -1
			response_count += 1
		} else {
			response := values[position]
			for index := position; index+1 < cache_count; index += 1 {
				keys[index] = keys[index+1]
				values[index] = values[index+1]
			}
			keys[cache_count-1], values[cache_count-1] = key, response
			responses[response_count] = response
			response_count += 1
		}
	}
	return hash_responses(&responses[0], response_count)
}
