package hash_map_separate_chaining

import "core:c"

MAX_OPERATIONS :: 512
MAX_ENTRIES :: 128
MAX_KEY :: i64(99999)
BUCKET_COUNT :: 16
MAX_INPUT_LENGTH :: 1537
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)
RESULT_MASK :: u64(0x7fffffffffffffff)

hash_byte :: proc(hash: u64, byte: u8) -> u64 {
	return (hash ^ u64(byte)) * FNV_PRIME
}

hash_i32 :: proc(hash_value: u64, value: i64) -> u64 {
	hash := hash_value
	bits := u32(value)
	for shift := 0; shift < 32; shift += 8 { hash = hash_byte(hash, u8(bits >> shift)) }
	return hash
}

find_entry :: proc(keys: [^]i64, next: [^]int, buckets: [^]int, key: i64) -> int {
	bucket := int(key % i64(BUCKET_COUNT))
	for entry := buckets[bucket]; entry >= 0; entry = next[entry] {
		if keys[entry] == key do return entry
	}
	return -1
}

@(export)
hash_map_separate_chaining :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	operation_count := input[0]
	if operation_count < 0 || operation_count > MAX_OPERATIONS || length != c.size_t(1 + 3 * operation_count) do return -1

	keys: [MAX_ENTRIES]i64
	mapped_values: [MAX_ENTRIES]i64
	next: [MAX_ENTRIES]int
	buckets: [BUCKET_COUNT]int
	free_slots: [MAX_ENTRIES]int
	for i := 0; i < MAX_ENTRIES; i += 1 { next[i] = -1; free_slots[i] = i }
	for i := 0; i < BUCKET_COUNT; i += 1 { buckets[i] = -1 }
	free_count := MAX_ENTRIES
	size := 0
	hash := FNV_OFFSET

	for operation := 0; operation < int(operation_count); operation += 1 {
		opcode := input[1+3*operation]
		key := input[2+3*operation]
		value := input[3+3*operation]
		result_code := u8(0)
		returned_value := i64(0)

		if opcode == 0 {
			if key < 0 || key > MAX_KEY || value < -2147483648 || value > 2147483647 do return -1
			bucket := int(key % i64(BUCKET_COUNT))
			entry := find_entry(&keys[0], &next[0], &buckets[0], key)
			if entry >= 0 { mapped_values[entry] = value } else {
				if size >= MAX_ENTRIES do return -1
				entry = free_slots[free_count-1]
				free_count -= 1
				keys[entry] = key; mapped_values[entry] = value
				next[entry] = buckets[bucket]; buckets[bucket] = entry; size += 1
			}
		} else if opcode == 1 {
			if key < 0 || key > MAX_KEY || value != 0 do return -1
			entry := find_entry(&keys[0], &next[0], &buckets[0], key)
			if entry >= 0 { result_code = 1; returned_value = mapped_values[entry] }
		} else if opcode == 2 {
			if key < 0 || key > MAX_KEY || value != 0 do return -1
			bucket := int(key % i64(BUCKET_COUNT))
			previous := -1
			entry := buckets[bucket]
			for entry >= 0 {
				following := next[entry]
				if keys[entry] == key {
					if previous < 0 { buckets[bucket] = following } else { next[previous] = following }
					free_slots[free_count] = entry; free_count += 1; size -= 1; break
				}
				previous = entry; entry = following
			}
		} else if opcode == 3 {
			if key < 0 || key > MAX_KEY || value != 0 do return -1
			if find_entry(&keys[0], &next[0], &buckets[0], key) >= 0 { result_code = 1 }
		} else if opcode == 4 {
			if key != 0 || value != 0 do return -1
			for i := 0; i < BUCKET_COUNT; i += 1 { buckets[i] = -1 }
			for i := 0; i < MAX_ENTRIES; i += 1 { next[i] = -1; free_slots[i] = i }
			free_count = MAX_ENTRIES; size = 0
		} else { return -1 }

		hash = hash_byte(hash, u8(opcode))
		hash = hash_byte(hash, result_code)
		if opcode == 1 && result_code == 1 { hash = hash_i32(hash, returned_value) }
	}
	return i64(hash & RESULT_MASK)
}
