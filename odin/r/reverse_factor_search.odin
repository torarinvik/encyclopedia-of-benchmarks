package reverse_factor_search

import "core:c"

MAX_TEXT :: 4096
MAX_PATTERN :: 128
MAX_INPUT_LENGTH :: 4227
MAX_STATES :: 2 * MAX_PATTERN + 1

@(export)
reverse_factor_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
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

	var transitions: [MAX_STATES*4]int
	var suffix_link: [MAX_STATES]int
	var max_length: [MAX_STATES]int
	var terminal: [MAX_STATES]bool
	for state := 0; state < MAX_STATES; state += 1 {
		suffix_link[state] = -1
		for symbol := 0; symbol < 4; symbol += 1 do transitions[state*4+symbol] = -1
	}
	state_count := 1
	last := 0
	for pos := 0; pos < m; pos += 1 {
		symbol := int(pattern[m-1-pos])
		current := state_count
		state_count += 1
		max_length[current] = max_length[last] + 1
		predecessor := last
		for predecessor >= 0 && transitions[predecessor*4+symbol] < 0 {
			transitions[predecessor*4+symbol] = current
			predecessor = suffix_link[predecessor]
		}
		if predecessor < 0 {
			suffix_link[current] = 0
		} else {
			target := transitions[predecessor*4+symbol]
			if max_length[predecessor] + 1 == max_length[target] {
				suffix_link[current] = target
			} else {
				clone := state_count
				state_count += 1
				for symbol_index := 0; symbol_index < 4; symbol_index += 1 {
					transitions[clone*4+symbol_index] = transitions[target*4+symbol_index]
				}
				max_length[clone] = max_length[predecessor] + 1
				suffix_link[clone] = suffix_link[target]
				for predecessor >= 0 && transitions[predecessor*4+symbol] == target {
					transitions[predecessor*4+symbol] = clone
					predecessor = suffix_link[predecessor]
				}
				suffix_link[target] = clone
				suffix_link[current] = clone
			}
		}
		last = current
	}
	for state := last; state >= 0; state = suffix_link[state] { terminal[state] = true }

	var count, offset_sum, offset_xor: i64
	period := m
	start := 0
	for start <= n-m {
		index := m-1
		state := 0
		shift := m
		for start+index >= 0 {
			target := transitions[state*4+int(text[start+index])]
			if target < 0 do break
			state = target
			if terminal[state] {
				period = shift
				shift = index
			}
			index -= 1
		}
		if index < 0 {
			count += 1
			offset_sum += i64(start)
			offset_xor ^= i64(start)
			shift = period
		}
		start += shift
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}
