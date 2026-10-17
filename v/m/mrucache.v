const max_operations = 128
const max_capacity = 16
const max_input_length = 387
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_byte(hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn hash_responses(responses &i32, count int) i64 {
	mut hash := hash_byte(fnv_offset, u8(count))
	hash = hash_byte(hash, u8(count >> 8))
	unsafe {
		for index in 0 .. count {
			bits := u32(responses[index])
			for shift in 0 .. 4 { hash = hash_byte(hash, u8(bits >> (shift * 8))) }
		}
	}
	return i64(hash & u64(0x7fffffffffffffff))
}

@[export: 'mrucache']
pub fn mrucache(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		capacity64, operation_count64 := input[0], input[1]
		if capacity64 < 1 || capacity64 > i64(max_capacity) || operation_count64 < 0 || operation_count64 > i64(max_operations)
			|| int(length) != 2 + 3 * int(operation_count64) { return -1 }
		capacity, operation_count := int(capacity64), int(operation_count64)
		mut keys := [max_capacity]i32{}
		mut values := [max_capacity]i32{}
		mut responses := [max_operations]i32{}
		mut cache_count := 0
		mut response_count := 0

		for step in 0 .. operation_count {
			operation, key64, value64 := input[2+3*step], input[3+3*step], input[4+3*step]
			if operation < 0 || operation > 1 || key64 < i64(-2147483648) || key64 > i64(2147483647)
				|| value64 < i64(-2147483648) || value64 > i64(2147483647) { return -1 }
			key, value := i32(key64), i32(value64)
			mut position := 0
			for position < cache_count && keys[position] != key { position++ }

			if operation == 0 {
				if value < 0 || value > 1_000_000 { return -1 }
				if position < cache_count {
					for index in position .. cache_count - 1 {
						keys[index] = keys[index + 1]
						values[index] = values[index + 1]
					}
					keys[cache_count - 1], values[cache_count - 1] = key, value
				} else {
					if cache_count == capacity { cache_count-- }
					keys[cache_count], values[cache_count] = key, value
					cache_count++
				}
			} else if position == cache_count {
				responses[response_count] = -1
				response_count++
			} else {
				response := values[position]
				for index in position .. cache_count - 1 {
					keys[index] = keys[index + 1]
					values[index] = values[index + 1]
				}
				keys[cache_count - 1], values[cache_count - 1] = key, response
				responses[response_count] = response
				response_count++
			}
		}
		return hash_responses(mut responses[0], response_count)
	}
}
