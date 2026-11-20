package maximal_shift_search

import "core:c"

MAX_TEXT :: 4096
MAX_PATTERN :: 128
MAX_INPUT_LENGTH :: 4227
ALPHABET :: 4

ms_match_shift :: proc(pattern: []u8, order_loc, order_symbol: []int,
		m, prefix_length, initial_shift: int) -> int {
	shift := initial_shift
	for shift < m {
		order_index := prefix_length - 1
		for order_index >= 0 {
			pattern_index := order_loc[order_index] - shift
			if pattern_index >= 0 && order_symbol[order_index] != int(pattern[pattern_index]) do break
			order_index -= 1
		}
		if order_index < 0 do break
		shift += 1
	}
	return shift
}

@(export)
maximal_shift_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n64, m64 := input[0], input[1]
	if n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN do return -1
	n, m := int(n64), int(m64)
	if length != c.size_t(2+n+m) do return -1
	var text: [MAX_TEXT]u8
	var pattern: [MAX_PATTERN]u8
	for q := 0; q < n; q += 1 {
		value := input[2+q]
		if value < 0 || value >= ALPHABET do return -1
		text[q] = u8(value)
	}
	for q := 0; q < m; q += 1 {
		value := input[2+n+q]
		if value < 0 || value >= ALPHABET do return -1
		pattern[q] = u8(value)
	}
	if n < m do return 0

	var leading_shift: [MAX_PATTERN]int
	var order_loc: [MAX_PATTERN+1]int
	var order_symbol: [MAX_PATTERN+1]int
	var quick_shift: [ALPHABET]int
	var adapted_shift: [MAX_PATTERN+1]int
	for i := 0; i < m; i += 1 {
		previous := i-1
		for previous >= 0 && pattern[previous] != pattern[i] { previous -= 1 }
		leading_shift[i] = i-previous
		position := i
		for position > 0 {
			prior_loc := order_loc[position-1]
			if leading_shift[prior_loc] > leading_shift[i] || (leading_shift[prior_loc] == leading_shift[i] && prior_loc > i) { break }
			order_loc[position] = prior_loc
			position -= 1
		}
		order_loc[position] = i
	}
	for i := 0; i < m; i += 1 { order_symbol[i] = int(pattern[order_loc[i]]) }
	order_loc[m] = m
	order_symbol[m] = -1
	for symbol := 0; symbol < ALPHABET; symbol += 1 { quick_shift[symbol] = m+1 }
	for i := 0; i < m; i += 1 { quick_shift[int(pattern[i])] = m-i }

	shift := 1
	adapted_shift[0] = 1
	for prefix_length := 1; prefix_length <= m; prefix_length += 1 {
		shift = ms_match_shift(pattern[:], order_loc[:], order_symbol[:], m, prefix_length, shift)
		adapted_shift[prefix_length] = shift
	}
	for prefix_length := 0; prefix_length <= m; prefix_length += 1 {
		shift = adapted_shift[prefix_length]
		for shift < m {
			pattern_index := order_loc[prefix_length] - shift
			if pattern_index < 0 || order_symbol[prefix_length] != int(pattern[pattern_index]) { break }
			shift += 1
			shift = ms_match_shift(pattern[:], order_loc[:], order_symbol[:], m, prefix_length, shift)
		}
		adapted_shift[prefix_length] = shift
	}

	var count, offset_sum, offset_xor: i64
	start := 0
	for start <= n-m {
		compared := 0
		for compared < m && order_symbol[compared] == int(text[start+order_loc[compared]]) { compared += 1 }
		if compared == m { count += 1; offset_sum += i64(start); offset_xor ^= i64(start) }
		lookahead := start+m
		if lookahead >= n { break }
		start += max(adapted_shift[compared], quick_shift[int(text[lookahead])])
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}
