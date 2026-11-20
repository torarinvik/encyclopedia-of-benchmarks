package skip_search

import "core:c"

@(export)
skip_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 4227 do return -1
	if input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 128 do return -1
	n := c.size_t(input[0])
	m := c.size_t(input[1])
	if length != 2 + n + m do return -1

	text: [4096]u8
	pattern: [128]u8
	for q := c.size_t(0); q < n; q += 1 {
		value := input[2 + q]
		if value < 0 || value > 3 do return -1
		text[q] = u8(value)
	}
	positions: [4][128]int
	bucket_sizes: [4]int
	for q := c.size_t(0); q < m; q += 1 {
		value := input[2 + n + q]
		if value < 0 || value > 3 do return -1
		symbol := int(value)
		pattern[q] = u8(value)
		positions[symbol][bucket_sizes[symbol]] = int(q)
		bucket_sizes[symbol] += 1
	}

	count: i64 = 0
	offset_sum: i64 = 0
	offset_xor: i64 = 0
	sample := m - 1
	for sample < n {
		symbol := int(text[sample])
		for item := 0; item < bucket_sizes[symbol]; item += 1 {
			start := int(sample) - positions[symbol][item]
			if start < 0 || c.size_t(start) > n - m do continue
			matched := 0
			for matched < int(m) && text[start + matched] == pattern[matched] { matched += 1 }
			if matched == int(m) {
				count += 1
				offset_sum += i64(start)
				offset_xor ^= i64(start)
			}
		}
		sample += m
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}
