package kmp_skip_search

import "core:c"

MAX_TEXT :: 4096
MAX_PATTERN :: 128
MAX_INPUT_LENGTH :: 4227

@(export)
kmp_skip_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n64, m64 := input[0], input[1]
	if n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN do return -1
	n, m := int(n64), int(m64)
	if length != c.size_t(2+n+m) do return -1
	var text: [MAX_TEXT]u8
	var pattern: [MAX_PATTERN]u8
	for q := 0; q < n; q += 1 {
		symbol := input[2+q]
		if symbol < 0 || symbol > 3 do return -1
		text[q] = u8(symbol)
	}
	for q := 0; q < m; q += 1 {
		symbol := input[2+n+q]
		if symbol < 0 || symbol > 3 do return -1
		pattern[q] = u8(symbol)
	}
	if n < m do return 0

	var mp_next: [MAX_PATTERN+1]int
	var kmp_next: [MAX_PATTERN+1]int
	q, border := 0, -1
	mp_next[0] = -1
	for q < m {
		for border >= 0 && pattern[q] != pattern[border] { border = mp_next[border] }
		q += 1
		border += 1
		mp_next[q] = border
	}
	q, border = 0, -1
	kmp_next[0] = -1
	for q < m {
		for border >= 0 && pattern[q] != pattern[border] { border = kmp_next[border] }
		q += 1
		border += 1
		if q < m && pattern[q] == pattern[border] { kmp_next[q] = kmp_next[border] }
		else { kmp_next[q] = border }
	}

	var last: [4]int
	for q := 0; q < 4; q += 1 { last[q] = -1 }
	var previous: [MAX_PATTERN]int
	for q := 0; q < m; q += 1 {
		symbol := int(pattern[q])
		previous[q] = last[symbol]
		last[symbol] = q
	}

	sample, i := -1, -1
	for {
		sample += m
		if sample >= n do return 0
		i = last[int(text[sample])]
		if i >= 0 do break
	}
	start, wall := sample-i, 0
	period := m-kmp_next[m]
	var count, offset_sum, offset_xor: i64
	for start <= n-m {
		if start > wall do wall = start
		k := wall-start
		for k < m && pattern[k] == text[start+k] { k += 1 }
		wall = start+k
		if k == m {
			count += 1
			offset_sum += i64(start)
			offset_xor ^= i64(start)
			i -= period
		} else {
			i = previous[i]
		}
		if i < 0 {
			found := false
			for {
				sample += m
				if sample >= n do break
				i = last[int(text[sample])]
				if i >= 0 { found = true; break }
			}
			if !found do break
		}

		kmp_start := start+k-kmp_next[k]
		k = kmp_next[k]
		start = sample-i
		for start < kmp_start || (kmp_start < start && start < wall) {
			if start < kmp_start {
				i = previous[i]
				if i < 0 {
					found := false
					for {
						sample += m
						if sample >= n do break
						i = last[int(text[sample])]
						if i >= 0 { found = true; break }
					}
					if !found do return (count << 36) | (offset_sum << 12) | offset_xor
				}
				start = sample-i
			} else {
				kmp_start += k-mp_next[k]
				k = mp_next[k]
			}
		}
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}
