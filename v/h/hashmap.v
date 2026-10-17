module hashmap

const max_operations = 128
const max_entries = 128
const max_initial_capacity = 64
const max_capacity = 256
const max_input_length = 2 + 3 * max_operations
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_byte(hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) *% fnv_prime
}

fn hash_key(key i64) u64 {
	mut hash := fnv_offset
	mut magnitude := u64(if key < 0 { -key } else { key })
	mut digits := [10]u8{}
	mut count := 0
	for {
		digits[count] = u8(magnitude % 10)
		count++
		magnitude /= 10
		if magnitude == 0 { break }
	}
	if key < 0 { hash = hash_byte(hash, u8(`-`)) }
	for count > 0 {
		count--
		hash = hash_byte(hash, u8(`0`) + digits[count])
	}
	return hash ^ (hash >> 16)
}

fn bucket_for(key i64, capacity int) int {
	return int(hash_key(key) & u64(capacity - 1))
}

fn put_i64_le(output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'hashmap']
pub fn hashmap(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		initial_capacity := input[0]
		operation_count := input[1]
		if initial_capacity < 1 || initial_capacity > max_initial_capacity ||
			(initial_capacity & (initial_capacity - 1)) != 0 || operation_count < 0 ||
			operation_count > max_operations || length != usize(2 + 3 * operation_count) { return -1 }
		for operation in 0 .. int(operation_count) {
			op := input[2 + 3 * operation]
			key := input[3 + 3 * operation]
			value := input[4 + 3 * operation]
			if op < 0 || op > 2 || key < -2147483648 || key > 2147483647 { return -1 }
			if op == 0 {
				if value < -2147483648 || value > 2147483647 { return -1 }
			} else if value != 0 { return -1 }
		}

		mut keys := [max_entries]i64{}
		mut values := [max_entries]i64{}
		mut results := [1 + 3 * max_operations + 2]i64{}
		mut next := [max_entries]int{}
		mut heads := [max_capacity]int{}
		mut tails := [max_capacity]int{}
		for i in 0 .. max_entries { next[i] = -1 }
		for i in 0 .. max_capacity { heads[i] = -1; tails[i] = -1 }
		mut size := 0
		mut map_capacity := int(initial_capacity)
		mut result_words := 1
		mut query_count := 0

		for operation in 0 .. int(operation_count) {
			op := input[2 + 3 * operation]
			key := input[3 + 3 * operation]
			value := input[4 + 3 * operation]
			bucket := bucket_for(key, map_capacity)
			mut entry := heads[bucket]
			for entry >= 0 && keys[entry] != key { entry = next[entry] }
			if op == 0 {
				if entry >= 0 { values[entry] = value; continue }
				if size >= max_entries { return -1 }
				entry = size
				size++
				keys[entry] = key
				values[entry] = value
				if heads[bucket] < 0 { heads[bucket] = entry } else { next[tails[bucket]] = entry }
				tails[bucket] = entry
				if size * 4 > map_capacity * 3 {
					mut order := [max_entries]int{}
					mut order_count := 0
					for old_bucket in 0 .. map_capacity {
						mut node := heads[old_bucket]
						for node >= 0 { order[order_count] = node; order_count++; node = next[node] }
					}
					map_capacity *= 2
					for i in 0 .. max_capacity { heads[i] = -1; tails[i] = -1 }
					for i in 0 .. size { next[i] = -1 }
					for i in 0 .. order_count {
						node := order[i]
						new_bucket := bucket_for(keys[node], map_capacity)
						if heads[new_bucket] < 0 { heads[new_bucket] = node } else { next[tails[new_bucket]] = node }
						tails[new_bucket] = node
					}
				}
			} else {
				results[result_words] = op
				result_words++
				if op == 1 {
					results[result_words] = if entry >= 0 { 1 } else { 0 }
					result_words++
					results[result_words] = if entry >= 0 { values[entry] } else { 0 }
					result_words++
				} else {
					results[result_words] = if entry >= 0 { 1 } else { 0 }
					result_words++
				}
				query_count++
			}
		}
		results[0] = query_count
		results[result_words] = size
		result_words++
		results[result_words] = map_capacity
		result_words++
		output_bytes := result_words * 8
		if unsafe { output == nil } || output_capacity < usize(output_bytes) { return -2 }
		for word in 0 .. result_words { put_i64_le(output, word, results[word]) }
		return i64(output_bytes)
	}
}
