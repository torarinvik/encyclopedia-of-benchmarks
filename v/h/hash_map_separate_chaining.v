module hash_map_separate_chaining

const max_operations = 512
const max_entries = 128
const max_key = i64(99999)
const bucket_count = 16
const max_input_length = 1537
const fnv_offset = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)
const result_mask = u64(0x7fffffffffffffff)

fn hash_byte(hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn hash_i32(hash_value u64, value i64) u64 {
	mut hash := hash_value
	bits := u32(i32(value))
	for shift in 0 .. 4 { hash = hash_byte(hash, u8((bits >> (shift * 8)) & 255)) }
	return hash
}

fn find_entry(mut keys [128]i64, mut next [128]int, mut buckets [16]int, key i64) int {
	bucket := int(key % bucket_count)
	mut entry := buckets[bucket]
	for entry >= 0 {
		if keys[entry] == key { return entry }
		entry = next[entry]
	}
	return -1
}

@[export: 'hash_map_separate_chaining']
pub fn hash_map_separate_chaining(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 1 || length > max_input_length { return -1 }
		operation_count := input[0]
		if operation_count < 0 || operation_count > max_operations || length != usize(1 + 3 * operation_count) { return -1 }

		mut keys := [128]i64{}
		mut mapped_values := [128]i64{}
		mut next := [128]int{init: -1}
		mut buckets := [16]int{init: -1}
		mut free_slots := [128]int{}
		for index in 0 .. 128 { free_slots[index] = index }
		mut free_count := 128
		mut size := 0
		mut hash := fnv_offset

		for operation in 0 .. int(operation_count) {
			opcode := input[1 + 3 * operation]
			key := input[2 + 3 * operation]
			value := input[3 + 3 * operation]
			mut result_code := u8(0)
			mut returned_value := i64(0)

			if opcode == 0 {
				if key < 0 || key > max_key || value < -2147483648 || value > 2147483647 { return -1 }
				bucket := int(key % bucket_count)
				mut entry := find_entry(mut keys, mut next, mut buckets, key)
				if entry >= 0 { mapped_values[entry] = value } else {
					if size >= max_entries { return -1 }
					free_count--
					entry = free_slots[free_count]
					keys[entry] = key; mapped_values[entry] = value
					next[entry] = buckets[bucket]; buckets[bucket] = entry; size++
				}
			} else if opcode == 1 {
				if key < 0 || key > max_key || value != 0 { return -1 }
				entry := find_entry(mut keys, mut next, mut buckets, key)
				if entry >= 0 { result_code = 1; returned_value = mapped_values[entry] }
			} else if opcode == 2 {
				if key < 0 || key > max_key || value != 0 { return -1 }
				bucket := int(key % bucket_count)
				mut previous := -1
				mut entry := buckets[bucket]
				for entry >= 0 {
					following := next[entry]
					if keys[entry] == key {
						if previous < 0 { buckets[bucket] = following } else { next[previous] = following }
						free_slots[free_count] = entry; free_count++; size--; break
					}
					previous = entry; entry = following
				}
			} else if opcode == 3 {
				if key < 0 || key > max_key || value != 0 { return -1 }
				result_code = if find_entry(mut keys, mut next, mut buckets, key) >= 0 { u8(1) } else { u8(0) }
			} else if opcode == 4 {
				if key != 0 || value != 0 { return -1 }
				for index in 0 .. bucket_count { buckets[index] = -1 }
				for index in 0 .. max_entries { next[index] = -1; free_slots[index] = index }
				free_count = max_entries; size = 0
			} else { return -1 }

			hash = hash_byte(hash, u8(opcode))
			hash = hash_byte(hash, result_code)
			if opcode == 1 && result_code == 1 { hash = hash_i32(hash, returned_value) }
		}
		return i64(hash & result_mask)
	}
}
