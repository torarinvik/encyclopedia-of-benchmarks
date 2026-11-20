package linear_hashing_trace

import "core:c"

bucket_index :: proc(key: i64, level, split: int) -> int {
	base := 1 << level
	remainder := key % i64(base)
	if remainder < 0 do remainder += i64(base)
	index := int(remainder)
	if index < split {
		remainder = key % i64(base << 1)
		if remainder < 0 do remainder += i64(base << 1)
		index = int(remainder)
	}
	return index
}

@(export)
linear_hashing_trace :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 128 do return -1
	operation_count := values[0]
	if operation_count < 0 || operation_count > 63 || length != c.size_t(1 + 2 * operation_count) do return -1

	head_counts: [32]int
	keys: [63]i64
	links: [63]int
	for bucket: int = 0; bucket < 32; bucket += 1 { head_counts[bucket] = -1 }
	level := 1
	split := 0
	live_count := 0
	allocated := 0
	result: i64 = 0

	for operation: int = 0; operation < int(operation_count); operation += 1 {
		opcode := values[1 + 2 * operation]
		key := values[2 + 2 * operation]
		if opcode < 0 || opcode > 2 || key < -1024 || key > 1023 do return -1
		bucket := bucket_index(key, level, split)
		previous := -1
		node := head_counts[bucket]
		for node != -1 && keys[node] != key {
			previous = node
			node = links[node]
		}
		found := node != -1
		succeeded: i64 = 0

		if opcode == 0 && !found {
			node = allocated
			allocated += 1
			keys[node] = key
			links[node] = head_counts[bucket]
			head_counts[bucket] = node
			live_count += 1
			succeeded = 1
			base := 1 << level
			bucket_count := base + split
			if bucket_count < 32 && live_count > 2 * bucket_count {
				old_bucket := split
				new_bucket := base + split
				current := head_counts[old_bucket]
				head_counts[old_bucket] = -1
				for current != -1 {
					following := links[current]
					remainder := keys[current] % i64(base << 1)
					if remainder < 0 do remainder += i64(base << 1)
					if int(remainder) == new_bucket {
						links[current] = head_counts[new_bucket]
						head_counts[new_bucket] = current
					} else {
						links[current] = head_counts[old_bucket]
						head_counts[old_bucket] = current
					}
					current = following
				}
				split += 1
				if split == base {
					level += 1
					split = 0
				}
			}
		} else if opcode == 1 && found {
			if previous == -1 do head_counts[bucket] = links[node]
			else do links[previous] = links[node]
			live_count -= 1
			succeeded = 1
		} else if opcode == 2 && found {
			succeeded = 1
		}
		result = (result << 1) | succeeded
	}
	return result
}
