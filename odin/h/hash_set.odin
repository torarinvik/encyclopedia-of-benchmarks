package hash_set

import "core:c"

MAX_IDS :: 64
MAX_INPUT_LENGTH :: 130
CAPACITY :: 1024
FNV_OFFSET_BASIS :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

adler_key :: proc "contextless" (id: i64) -> u64 {
	a, b: u64 = 1, 0
	a = (a + 107) % 65521; b = (b + a) % 65521
	a = (a + 101) % 65521; b = (b + a) % 65521
	a = (a + 121) % 65521; b = (b + a) % 65521
	if id >= 10 {
		a = (a + u64(id / 10 + 48)) % 65521
		b = (b + a) % 65521
	}
	a = (a + u64(id % 10 + 48)) % 65521
	b = (b + a) % 65521
	return (b << 16) | a
}

bucket_for_id :: proc "contextless" (id: i64) -> int {
	hash := adler_key(id)
	return int((CAPACITY - 1) & (hash ^ (hash >> 12)))
}

fnv_word :: proc "contextless" (hash: u64, value: i64) -> u64 {
	bits := u64(value)
	result := hash
	for byte := 0; byte < 8; byte += 1 {
		result = (result ^ ((bits >> (8 * byte)) & 255)) * FNV_PRIME
	}
	return result
}

@(export)
hash_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_IDS do return -1
	add_count := int(input[0])
	query_count_index := 1 + add_count
	if c.size_t(query_count_index) >= length do return -1
	if input[query_count_index] < 0 || input[query_count_index] > MAX_IDS do return -1
	query_count := int(input[query_count_index])
	if length != c.size_t(2 + add_count + query_count) do return -1

	for index := 0; index < add_count; index += 1 {
		if input[1 + index] < 0 || input[1 + index] >= MAX_IDS do return -1
	}
	for index := 0; index < query_count; index += 1 {
		if input[query_count_index + 1 + index] < 0 || input[query_count_index + 1 + index] >= MAX_IDS do return -1
	}

	var occupied: [CAPACITY]bool
	var slot_ids: [CAPACITY]i64
	set_length: i64 = 0
	for index := 0; index < add_count; index += 1 {
		id := input[1 + index]
		bucket := bucket_for_id(id)
		if !occupied[bucket] {
			occupied[bucket] = true
			slot_ids[bucket] = id
			set_length += 1
		} else if slot_ids[bucket] != id {
			return -1
		}
	}

	result := fnv_word(FNV_OFFSET_BASIS, set_length)
	for index := 0; index < query_count; index += 1 {
		id := input[query_count_index + 1 + index]
		bucket := bucket_for_id(id)
		contains: i64 = 0
		if occupied[bucket] && slot_ids[bucket] == id do contains = 1
		result = fnv_word(result, contains)
	}
	return i64(result & 0x7fffffffffffffff)
}
