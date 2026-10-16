package chaining

import "core:c"

@(export)
chaining :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 260 do return -1
	bucket_count_value := input[0]
	operation_count_value := input[1]
	if bucket_count_value < 1 || bucket_count_value > 127 || operation_count_value < 0 || operation_count_value > 128 do return -1
	bucket_count := int(bucket_count_value)
	operation_count := int(operation_count_value)
	if int(length) != 2 + 2 * operation_count do return -1

	heads: [127]i64
	keys: [128]i64
	next: [128]i64
	for bucket := 0; bucket < bucket_count; bucket += 1 {
		heads[bucket] = -1
	}
	inserted := 0
	query_count := 0
	mask: i64 = 0
	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		offset := 2 + 2 * operation_index
		operation := input[offset]
		key := input[offset + 1]
		if (operation != 0 && operation != 1) || key < 0 || key > 2147483647 do return -1
		bucket := int(key % bucket_count_value)
		if operation == 0 {
			if inserted >= 128 do return -1
			keys[inserted] = key
			next[inserted] = -1
			if heads[bucket] < 0 do heads[bucket] = i64(inserted)
			else {
				node := heads[bucket]
				for next[int(node)] >= 0 { node = next[int(node)] }
				next[int(node)] = i64(inserted)
			}
			inserted += 1
		} else {
			if query_count >= 63 do return -1
			node := heads[bucket]
			for node >= 0 && keys[int(node)] != key {
				node = next[int(node)]
			}
			if node >= 0 do mask += i64(u64(1) << u64(query_count))
			query_count += 1
		}
	}
	return mask
}
