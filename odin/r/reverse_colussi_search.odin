package reverse_colussi_search

import "core:c"

MAX_TEXT :: 4096
MAX_PATTERN :: 128
MAX_INPUT_LENGTH :: 4227

@(export)
reverse_colussi_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n64, m64 := input[0], input[1]
	if n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN do return -1
	n, m := int(n64), int(m64)
	if length != c.size_t(2+n+m) do return -1
	var text: [MAX_TEXT]u8
	var pattern: [MAX_PATTERN]u8
	for q := 0; q < n; q += 1 {
		value := input[2+q]
		if value < 0 || value > 3 do return -1
		text[q] = u8(value)
	}
	for q := 0; q < m; q += 1 {
		value := input[2+n+q]
		if value < 0 || value > 3 do return -1
		pattern[q] = u8(value)
	}
	if n < m do return 0

	var hmin: [MAX_PATTERN+1]int
	var kmin: [MAX_PATTERN]int
	var rmin: [MAX_PATTERN]int
	var order: [MAX_PATTERN]int
	var good_suffix: [MAX_PATTERN+1]int
	var bad_character: [4*(MAX_PATTERN+1)]int
	for shift := 1; shift <= m; shift += 1 {
		last_mismatch := shift-1
		for pos := shift; pos < m; pos += 1 {
			if pattern[pos] != pattern[pos-shift] { last_mismatch = pos }
		}
		hmin[shift] = last_mismatch
	}
	shift := m
	for shift > 0 {
		end := hmin[shift]
		if end != m-1 { kmin[end] = shift }
		shift -= 1
	}
	next_boundary := m
	end := m-1
	for end >= 0 {
		if hmin[end+1] == end { next_boundary = end+1 }
		rmin[end] = next_boundary
		end -= 1
	}

	order[0] = m-1
	cursor := 0
	for shift := 1; shift <= m; shift += 1 {
		h_end := hmin[shift]
		if h_end != m-1 && kmin[h_end] == shift {
			cursor += 1
			order[cursor] = h_end
			good_suffix[cursor] = shift
		}
	}
	cursor = m-1
	end = m-2
	for end >= 0 {
		if kmin[end] == 0 {
			order[cursor] = end
			good_suffix[cursor] = rmin[end]
			cursor -= 1
		}
		end -= 1
	}
	good_suffix[m] = rmin[0]

	for symbol := 0; symbol < 4; symbol += 1 {
		for prior_shift := 1; prior_shift <= m; prior_shift += 1 {
			boundary := m-prior_shift-1
			for candidate := 1; candidate <= m; candidate += 1 {
				if candidate < m && int(pattern[m-candidate-1]) != symbol { continue }
				if candidate <= boundary && pattern[m-candidate-prior_shift-1] != pattern[boundary] { continue }
				bad_character[symbol*(MAX_PATTERN+1)+prior_shift] = candidate
				break
			}
		}
	}

	var count, offset_sum, offset_xor: i64
	start, shift_state := 0, m
	last_start := n-m
	for start <= last_start {
		for start <= last_start && pattern[m-1] != text[start+m-1] {
			shift_state = bad_character[int(text[start+m-1])*(MAX_PATTERN+1)+shift_state]
			start += shift_state
		}
		if start > last_start do break
		index := 1
		for index < m && pattern[order[index]] == text[start+order[index]] { index += 1 }
		if index == m {
			count += 1
			offset_sum += i64(start)
			offset_xor ^= i64(start)
		}
		shift_state = good_suffix[index]
		start += shift_state
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}
