package hash_map_cuckoo_hashing

import "core:c"

MAX_INPUT_LENGTH :: 130
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

fnv_word :: proc "contextless" (hash: u64, value: i64) -> u64 {
	bits := u64(value)
	result := hash
	for byte := 0; byte < 8; byte += 1 {
		result = (result ^ ((bits >> (8 * byte)) & 255)) * FNV_PRIME
	}
	return result
}

positive_remainder :: proc "contextless" (value: i64, capacity: int) -> int {
	rem := int(value % i64(capacity))
	if rem < 0 { rem += capacity }
	return rem
}

hash1 :: proc "contextless" (key: i64, capacity: int) -> int {
	return positive_remainder(key, capacity)
}

hash2 :: proc "contextless" (key: i64, capacity: int) -> int {
	quotient := key / i64(capacity)
	return positive_remainder(quotient, capacity)
}

@(export)
hash_map_cuckoo_hashing :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	capacity_value, count_value := values[0], values[1]
	if capacity_value < 16 || capacity_value > 256 || count_value < 0 || count_value > 128 do return -1
	capacity := int(capacity_value)
	if (capacity & (capacity - 1)) != 0 || length != c.size_t(count_value + 2) do return -1
	count := int(count_value)
	var keys: [128]i64
	var buckets: [128]int
	for i := 0; i < count; i += 1 {
		key := values[2 + i]
		if key < -2147483647 || key > 2147483647 do return -1
		keys[i] = key
		buckets[i] = hash1(key, capacity)
		for j := 0; j < i; j += 1 { if keys[j] == key do return -1 }
	}

	class_a := count == 2 && buckets[0] == buckets[1] && hash2(keys[0], capacity) != buckets[0]
	class_b := true
	for i := 0; i < count; i += 1 {
		for j := 0; j < i; j += 1 { if buckets[i] == buckets[j] do class_b = false }
	}
	if !class_a && !class_b do return -1

	var positions: [128]i64
	final_capacity := capacity
	if class_a {
		positions[0] = i64(hash2(keys[0], capacity))
		positions[1] = i64(buckets[0])
	} else {
		for count * 10 > final_capacity * 7 { final_capacity *= 2 }
		for i := 0; i < count; i += 1 { positions[i] = i64(hash1(keys[i], final_capacity)) }
	}

	hash := fnv_word(FNV_OFFSET, count_value)
	for i := 0; i < count; i += 1 { hash = fnv_word(hash, positions[i]) }
	return i64(hash & 0x7fffffffffffffff)
}
