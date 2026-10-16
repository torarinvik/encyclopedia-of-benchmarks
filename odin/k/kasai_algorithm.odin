package kasai_algorithm

import "core:c"

MAX_LENGTH :: 512
FNV_OFFSET_BASIS :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

fnv_word :: proc "contextless" (hash: u64, value: i64) -> u64 {
	bits := u64(value)
	result := hash
	for byte := 0; byte < 8; byte += 1 {
		result = (result ^ ((bits >> (8 * byte)) & 255)) * FNV_PRIME
	}
	return result
}

@(export)
kasai_algorithm :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 do return -1
	if values[0] < 0 || values[0] > i64(MAX_LENGTH) do return -1
	n := int(values[0])
	if length != c.size_t(1 + 2 * n) do return -1
	for i := 0; i < n; i += 1 {
		if values[1 + i] < 0 || values[1 + i] > 127 do return -1
	}

	var suffixes: [MAX_LENGTH]int
	var rank: [MAX_LENGTH]int
	var seen: [MAX_LENGTH]bool
	var lcp: [MAX_LENGTH]i64
	for position := 0; position < n; position += 1 {
		suffix_value := values[1 + n + position]
		if suffix_value < 0 || suffix_value >= i64(n) do return -1
		suffix := int(suffix_value)
		if seen[suffix] do return -1
		seen[suffix] = true
		suffixes[position] = suffix
		rank[suffix] = position
	}

	for position := 1; position < n; position += 1 {
		left, right := suffixes[position - 1], suffixes[position]
		left_tail_rank := -1
		right_tail_rank := -1
		if left + 1 < n { left_tail_rank = rank[left + 1] }
		if right + 1 < n { right_tail_rank = rank[right + 1] }
		left_byte, right_byte := values[1 + left], values[1 + right]
		if left_byte > right_byte || (left_byte == right_byte && left_tail_rank >= right_tail_rank) do return -1
	}

	common := 0
	for start := 0; start < n; start += 1 {
		current_rank := rank[start]
		if current_rank == n - 1 { common = 0; continue }
		next_start := suffixes[current_rank + 1]
		for start + common < n && next_start + common < n && values[1 + start + common] == values[1 + next_start + common] {
			common += 1
		}
		lcp[current_rank] = i64(common)
		if common > 0 { common -= 1 }
	}

	hash := fnv_word(FNV_OFFSET_BASIS, i64(n))
	for i := 0; i < n; i += 1 { hash = fnv_word(hash, lcp[i]) }
	return i64(hash & 0x7fffffffffffffff)
}
