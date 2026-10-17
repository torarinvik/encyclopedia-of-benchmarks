module clojure_persistent_list_queue

const max_operations = 256
const max_queue_length = 64
const max_valid_input_length = 513
const max_parseable_input_length = 514
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_byte(mut hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn hash_u16(mut hash u64, value u16) u64 {
	for shift in 0 .. 2 { hash = hash_byte(mut hash, u8((value >> u16(shift * 8)) & 255)) }
	return hash
}

fn hash_i32(mut hash u64, value i32) u64 {
	bits := u32(value)
	for shift in 0 .. 4 { hash = hash_byte(mut hash, u8((bits >> u32(shift * 8)) & 255)) }
	return hash
}

fn hash_i64(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = hash_byte(mut hash, u8((bits >> u64(shift * 8)) & 255)) }
	return hash
}

@[export: 'clojure_persistent_list_queue']
pub fn clojure_persistent_list_queue(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_operations { return -1 }
		operation_count := int(input[0])
		if length != usize(1 + 2 * operation_count) || length > max_valid_input_length { return -1 }
		mut newest_first := [64]i32{}
		mut queue_size := 0
		mut results := [256]i64{}
		mut opcodes := [256]u8{}
		for operation in 0 .. operation_count {
			offset := 1 + 2 * operation
			opcode_value := input[offset]
			argument := input[offset + 1]
			if opcode_value < 0 || opcode_value > 3 { return -1 }
			opcode := u8(opcode_value)
			opcodes[operation] = opcode
			if opcode == 0 {
				if argument < -2147483648 || argument > 2147483647 || queue_size >= max_queue_length { return -1 }
				for index := queue_size; index > 0; index-- { newest_first[index] = newest_first[index - 1] }
				newest_first[0] = i32(argument)
				queue_size++
				results[operation] = i64(queue_size)
			} else if opcode == 1 {
				if argument != 0 { return -1 }
				if queue_size > 0 { queue_size-- }
				results[operation] = i64(queue_size)
			} else if opcode == 2 {
				if argument != 0 { return -1 }
				results[operation] = if queue_size == 0 { i64(-9223372036854775807 - 1) } else { i64(newest_first[queue_size - 1]) }
			} else {
				if argument != 0 { return -1 }
				results[operation] = if queue_size == 0 { 1 } else { 0 }
			}
		}
		mut hash := fnv_offset
		hash = hash_u16(mut hash, u16(operation_count))
		for operation in 0 .. operation_count {
			hash = hash_byte(mut hash, opcodes[operation])
			hash = hash_i64(mut hash, results[operation])
		}
		hash = hash_u16(mut hash, u16(queue_size))
		for index := queue_size - 1; index >= 0; index-- { hash = hash_i32(mut hash, newest_first[index]) }
		return i64(hash & u64(0x7fffffffffffffff))
	}
}
