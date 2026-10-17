package hashmap

import "core:c"

max_operations :: 128
max_entries :: 128
max_initial_capacity :: 64
max_capacity :: 256
max_input_length :: 2 + 3 * max_operations
fnv_offset :: u64(14695981039346656037)
fnv_prime :: u64(1099511628211)

hash_byte :: proc "contextless" (hash: u64, byte: u8) -> u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

hash_key :: proc "contextless" (key: i64) -> u64 {
	hash := fnv_offset
	magnitude := u64(if key < 0 { -key } else { key })
	digits: [10]u8
	count := 0
	for {
		digits[count] = u8(magnitude % 10)
		count += 1
		magnitude /= 10
		if magnitude == 0 { break }
	}
	if key < 0 { hash = hash_byte(hash, u8('-')) }
	for count > 0 {
		count -= 1
		hash = hash_byte(hash, u8('0' + digits[count]))
	}
	return hash ^ (hash >> 16)
}

bucket_for :: proc "contextless" (key: i64, capacity: int) -> int {
	return int(hash_key(key) & u64(capacity - 1))
}

put_i64_le :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[word*8+byte] = u8((bits >> (byte*8)) & 255)
	}
}

@(export)
hashmap :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > max_input_length { return -1 }
	initial_capacity := input[0]
	operation_count := input[1]
	if initial_capacity < 1 || initial_capacity > max_initial_capacity ||
		(initial_capacity & (initial_capacity - 1)) != 0 || operation_count < 0 ||
		operation_count > max_operations || length != c.size_t(2 + 3*operation_count) { return -1 }
	for operation := 0; operation < int(operation_count); operation += 1 {
		op := input[2+3*operation]
		key := input[3+3*operation]
		value := input[4+3*operation]
		if op < 0 || op > 2 || key < -2147483648 || key > 2147483647 { return -1 }
		if op == 0 {
			if value < -2147483648 || value > 2147483647 { return -1 }
		} else if value != 0 { return -1 }
	}

	var keys: [max_entries]i64
	var values: [max_entries]i64
	var results: [1+3*max_operations+2]i64
	var next: [max_entries]int
	var heads: [max_capacity]int
	var tails: [max_capacity]int
	for i := 0; i < max_entries; i += 1 { next[i] = -1 }
	for i := 0; i < max_capacity; i += 1 { heads[i] = -1; tails[i] = -1 }
	size := 0
	map_capacity := int(initial_capacity)
	result_words := 1
	query_count := 0

	for operation := 0; operation < int(operation_count); operation += 1 {
		op := input[2+3*operation]
		key := input[3+3*operation]
		value := input[4+3*operation]
		bucket := bucket_for(key, map_capacity)
		entry := heads[bucket]
		for entry >= 0 && keys[entry] != key { entry = next[entry] }
		if op == 0 {
			if entry >= 0 { values[entry] = value; continue }
			if size >= max_entries { return -1 }
			entry = size
			size += 1
			keys[entry] = key
			values[entry] = value
			if heads[bucket] < 0 { heads[bucket] = entry } else { next[tails[bucket]] = entry }
			tails[bucket] = entry
			if size*4 > map_capacity*3 {
				var order: [max_entries]int
				order_count := 0
				for old_bucket := 0; old_bucket < map_capacity; old_bucket += 1 {
					node := heads[old_bucket]
					for node >= 0 { order[order_count] = node; order_count += 1; node = next[node] }
				}
				map_capacity *= 2
				for i := 0; i < max_capacity; i += 1 { heads[i] = -1; tails[i] = -1 }
				for i := 0; i < size; i += 1 { next[i] = -1 }
				for i := 0; i < order_count; i += 1 {
					node := order[i]
					new_bucket := bucket_for(keys[node], map_capacity)
					if heads[new_bucket] < 0 { heads[new_bucket] = node } else { next[tails[new_bucket]] = node }
					tails[new_bucket] = node
				}
			}
		} else {
			results[result_words] = op
			result_words += 1
			if op == 1 {
				results[result_words] = i64(if entry >= 0 { 1 } else { 0 })
				result_words += 1
				results[result_words] = if entry >= 0 { values[entry] } else { 0 }
				result_words += 1
			} else {
				results[result_words] = i64(if entry >= 0 { 1 } else { 0 })
				result_words += 1
			}
			query_count += 1
		}
	}
	results[0] = i64(query_count)
	results[result_words] = i64(size)
	result_words += 1
	results[result_words] = i64(map_capacity)
	result_words += 1
	output_bytes := result_words * 8
	if output == nil || output_capacity < c.size_t(output_bytes) { return -2 }
	for word := 0; word < result_words; word += 1 { put_i64_le(output, word, results[word]) }
	return i64(output_bytes)
}
