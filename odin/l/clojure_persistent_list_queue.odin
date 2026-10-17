package clojure_persistent_list_queue

import "core:c"

MAX_OPERATIONS :: 256
MAX_QUEUE_LENGTH :: 64
MAX_VALID_INPUT_LENGTH :: 513
MAX_PARSEABLE_INPUT_LENGTH :: 514
FNV_OFFSET :: u64(14695981039346656037)
FNV_PRIME :: u64(1099511628211)

hash_byte :: proc "contextless" (hash: ^u64, byte: u8) {
	hash^ = (hash^ ^ u64(byte)) * FNV_PRIME
}

hash_u16 :: proc "contextless" (hash: ^u64, value: u16) {
	for byte in 0 ..< 2 { hash_byte(hash, u8((value >> (8*byte)) & 255)) }
}

hash_i32 :: proc "contextless" (hash: ^u64, value: i32) {
	bits := transmute(u32)value
	for byte in 0 ..< 4 { hash_byte(hash, u8((bits >> (8*byte)) & 255)) }
}

hash_i64 :: proc "contextless" (hash: ^u64, value: i64) {
	bits := transmute(u64)value
	for byte in 0 ..< 8 { hash_byte(hash, u8((bits >> (8*byte)) & 255)) }
}

@(export)
clojure_persistent_list_queue :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
	operation_count := int(input[0])
	if length != 1 + 2*operation_count || length > MAX_VALID_INPUT_LENGTH do return -1

	var newest_first: [MAX_QUEUE_LENGTH]i32
	queue_size := 0
	var results: [MAX_OPERATIONS]i64
	var opcodes: [MAX_OPERATIONS]u8
	for operation in 0 ..< operation_count {
		offset := 1 + 2*operation
		opcode_value, argument := input[offset], input[offset+1]
		if opcode_value < 0 || opcode_value > 3 do return -1
		opcode := u8(opcode_value)
		opcodes[operation] = opcode
		if opcode == 0 {
			if argument < -2147483648 || argument > 2147483647 || queue_size >= MAX_QUEUE_LENGTH do return -1
			for index := queue_size; index > 0; index -= 1 { newest_first[index] = newest_first[index-1] }
			newest_first[0] = i32(argument)
			queue_size += 1
			results[operation] = i64(queue_size)
		} else if opcode == 1 {
			if argument != 0 do return -1
			if queue_size > 0 do queue_size -= 1
			results[operation] = i64(queue_size)
		} else if opcode == 2 {
			if argument != 0 do return -1
			results[operation] = if queue_size == 0 do i64(-9223372036854775807 - 1) else i64(newest_first[queue_size-1])
		} else {
			if argument != 0 do return -1
			results[operation] = if queue_size == 0 do 1 else 0
		}
	}

	hash := FNV_OFFSET
	hash_u16(&hash, u16(operation_count))
	for operation in 0 ..< operation_count {
		hash_byte(&hash, opcodes[operation])
		hash_i64(&hash, results[operation])
	}
	hash_u16(&hash, u16(queue_size))
	for index := queue_size-1; index >= 0; index -= 1 { hash_i32(&hash, newest_first[index]) }
	return i64(hash & 0x7fffffffffffffff)
}
