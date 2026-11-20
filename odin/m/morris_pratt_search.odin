package morris_pratt_search

import "core:c"

@(export)
morris_pratt_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 4227 do return -1
	if input[0] < 0 || input[0] > 4096 || input[1] < 1 || input[1] > 128 do return -1
	n := int(input[0])
	m := int(input[1])
	if length != c.size_t(2 + n + m) do return -1
	pattern_start := 2 + n
	for q := 0; q < n + m; q += 1 {
		if input[2 + q] < 0 || input[2 + q] > 3 do return -1
	}

	mp_next: [129]i64
	mp_next[0] = -1
	for index := 0; index < m; index += 1 {
		border := mp_next[index]
		for border >= 0 && input[pattern_start + index] != input[pattern_start + int(border)] {
			border = mp_next[int(border)]
		}
		mp_next[index + 1] = border + 1
	}

	matched := 0
	count: i64 = 0
	offset_sum: i64 = 0
	offset_xor: i64 = 0
	for text_index := 0; text_index < n; text_index += 1 {
		for matched >= 0 && input[pattern_start + matched] != input[2 + text_index] {
			matched = int(mp_next[matched])
		}
		matched += 1
		if matched == m {
			start := i64(text_index + 1 - matched)
			count += 1
			offset_sum += start
			offset_xor ^= start
			matched = int(mp_next[m])
		}
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}
