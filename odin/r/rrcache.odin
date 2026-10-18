package rrcache

import "core:c"

MAX_OPERATIONS :: 32
MAX_INPUT_LENGTH :: 3 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES :: 8 * MAX_OPERATIONS
JAVA_MULTIPLIER :: u64(0x5DEECE66D)
JAVA_ADDEND :: u64(0xB)
JAVA_MASK :: (u64(1) << 48) - 1

java_next_bits :: proc "contextless" (state: ^u64, bits: u32) -> u32 {
	state^ = (state^ *% JAVA_MULTIPLIER +% JAVA_ADDEND) & JAVA_MASK
	return u32(state^ >> (48 - bits))
}

java_next_int :: proc "contextless" (state: ^u64, bound: u32) -> u32 {
	if (bound & (bound - 1)) == 0 {
		return u32((u64(bound) * u64(java_next_bits(state, 31))) >> 31)
	}
	for {
		bits := java_next_bits(state, 31)
		value := bits % bound
		if u64(bits) - u64(value) + u64(bound - 1) <= u64(0x7fffffff) do return value
	}
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
rrcache :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
		capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > 8 || input[2] < 0 || input[2] > MAX_OPERATIONS do return -1
	cache_capacity := int(input[0])
	operation_count := int(input[2])
	if int(length) != 3 + 3 * operation_count do return -1

	keys: [8]i64 = {}
	values: [8]i64 = {}
	results: [MAX_OPERATIONS]i64 = {}
	size := 0
	random_state := (transmute(u64)input[1] ^ JAVA_MULTIPLIER) & JAVA_MASK

	for operation := 0; operation < operation_count; operation += 1 {
		offset := 3 + 3 * operation
		opcode := input[offset]
		key := input[offset + 1]
		value := input[offset + 2]
		if opcode == 0 {
			if key < 1 || key > 1024 || value < 100 || value > 1_000_000 do return -1
			index := 0
			for index < size && keys[index] != key { index += 1 }
			if index < size {
				values[index] = value
			} else {
				if size == cache_capacity {
					evicted := int(java_next_int(&random_state, u32(size)))
					for move := evicted; move+1 < size; move += 1 {
						keys[move] = keys[move+1]
						values[move] = values[move+1]
					}
					size -= 1
				}
				keys[size] = key
				values[size] = value
				size += 1
			}
			results[operation] = -2
		} else if opcode == 1 {
			if key < 1 || key > 1024 || value != 0 do return -1
			index := 0
			for index < size && keys[index] != key { index += 1 }
			results[operation] = -1
			if index < size { results[operation] = values[index] }
		} else if opcode == 2 {
			if key != 0 || value != 0 do return -1
			results[operation] = i64(size)
		} else do return -1
	}

	output_bytes := operation_count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for operation := 0; operation < operation_count; operation += 1 {
		put_i64_le(&staged[0], operation*8, results[operation])
	}
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
