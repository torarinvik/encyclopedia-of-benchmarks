package length_limited_huffman_package_merge

import "core:c"

MAX_SYMBOLS :: 12
MAX_LEVELS :: 10
MAX_ITEMS :: 24
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(15)

@(export)
length_limited_huffman_package_merge :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value := input[0]
	limit_value := input[1]
	if n_value < 2 || n_value > MAX_SYMBOLS || limit_value < 1 || limit_value > 6 ||
		n_value > (i64(1) << int(limit_value)) do return -1
	n := int(n_value)
	limit := int(limit_value)
	if length != c.size_t(n+2) do return -1

	weights: [MAX_SYMBOLS]i64
	for i := 0; i < n; i += 1 {
		weight := input[i+2]
		if weight < 0 || weight > 1_000_000 do return -1
		weights[i] = weight
	}
	for i := 1; i < n; i += 1 {
		key := weights[i]
		j := i
		for j > 0 && weights[j-1] > key {
			weights[j] = weights[j-1]
			j -= 1
		}
		weights[j] = key
	}

	lists: [MAX_LEVELS][MAX_ITEMS]i64
	counts: [MAX_LEVELS]int
	for level := 0; level < limit; level += 1 {
		for i := 0; i < n; i += 1 { lists[level][i] = weights[i] }
		counts[level] = n
	}

	remaining := i64(n-1) << limit
	total: i64 = 0
	level := 0
	for remaining > 0 {
		for level < MAX_LEVELS && counts[level] == 0 { level += 1 }
		if level >= MAX_LEVELS do return -1

		width := i64(1) << level
		needed := remaining & -remaining
		if width > needed do return -1
		if width == needed {
			total += lists[level][0]
			for i := 1; i < counts[level]; i += 1 { lists[level][i-1] = lists[level][i] }
			counts[level] -= 1
			remaining -= width
			if remaining == 0 do break
		}

		package_count := counts[level] / 2
		packages: [MAX_ITEMS]i64
		for i := 0; i < package_count; i += 1 {
			packages[i] = lists[level][2*i] + lists[level][2*i+1]
		}
		counts[level] = 0

		next_level := level+1
		if next_level >= MAX_LEVELS do return -1
		merged: [MAX_ITEMS]i64
		package_index := 0
		existing_index := 0
		merged_count := 0
		for package_index < package_count && existing_index < counts[next_level] {
			if packages[package_index] <= lists[next_level][existing_index] {
				if merged_count >= MAX_ITEMS do return -1
				merged[merged_count] = packages[package_index]
				package_index += 1
			} else {
				if merged_count >= MAX_ITEMS do return -1
				merged[merged_count] = lists[next_level][existing_index]
				existing_index += 1
			}
			merged_count += 1
		}
		for package_index < package_count {
			if merged_count >= MAX_ITEMS do return -1
			merged[merged_count] = packages[package_index]
			package_index += 1
			merged_count += 1
		}
		for existing_index < counts[next_level] {
			if merged_count >= MAX_ITEMS do return -1
			merged[merged_count] = lists[next_level][existing_index]
			existing_index += 1
			merged_count += 1
		}
		lists[next_level] = merged
		counts[next_level] = merged_count
		level = next_level
	}
	return total
}
