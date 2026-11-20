package forward_dawg_matching

import "core:c"

MAX_TEXT :: 4096
MAX_PATTERN :: 128
MAX_INPUT :: 4227
MAX_STATES :: 2 * MAX_PATTERN + 2

Suffix_Automaton :: struct {
	transition: [MAX_STATES][4]i64,
	suffix_link: [MAX_STATES]i64,
	max_length: [MAX_STATES]i64,
	state_count: int,
}

init_sam :: proc(sam: ^Suffix_Automaton) {
	sam.state_count = 1
	for state in 0..<MAX_STATES {
		sam.suffix_link[state] = -1
		sam.max_length[state] = 0
		for symbol in 0..<4 { sam.transition[state][symbol] = -1 }
	}
}

extend :: proc(sam: ^Suffix_Automaton, last: i64, symbol: int) -> i64 {
	if sam.state_count >= MAX_STATES { return -1 }
	current := sam.state_count
	sam.state_count += 1
	sam.max_length[current] = sam.max_length[int(last)] + 1
	state := last
	for state >= 0 && sam.transition[int(state)][symbol] < 0 {
		sam.transition[int(state)][symbol] = i64(current)
		state = sam.suffix_link[int(state)]
	}
	if state < 0 {
		sam.suffix_link[current] = 0
	} else {
		target := sam.transition[int(state)][symbol]
		if sam.max_length[int(state)] + 1 == sam.max_length[int(target)] {
			sam.suffix_link[current] = target
		} else {
			if sam.state_count >= MAX_STATES { return -1 }
			clone := sam.state_count
			sam.state_count += 1
			sam.transition[clone] = sam.transition[int(target)]
			sam.suffix_link[clone] = sam.suffix_link[int(target)]
			sam.max_length[clone] = sam.max_length[int(state)] + 1
			for state >= 0 && sam.transition[int(state)][symbol] == target {
				sam.transition[int(state)][symbol] = i64(clone)
				state = sam.suffix_link[int(state)]
			}
			sam.suffix_link[int(target)] = i64(clone)
			sam.suffix_link[current] = i64(clone)
		}
	}
	return i64(current)
}

search :: proc(sam: ^Suffix_Automaton, input: [^]i64, n, m: int) -> i64 {
	state := 0
	matched, count, sum, xor_offsets := i64(0), i64(0), i64(0), i64(0)
	for position := 0; position < n; position += 1 {
		symbol := int(input[2 + position])
		target := sam.transition[state][symbol]
		if target >= 0 {
			matched += 1
			state = int(target)
		} else {
			for state != 0 && sam.transition[state][symbol] < 0 {
				state = int(sam.suffix_link[state])
			}
			target = sam.transition[state][symbol]
			if target >= 0 {
				matched = sam.max_length[state] + 1
				state = int(target)
			} else {
				matched = 0
				state = 0
			}
		}
		if matched == i64(m) {
			start := i64(position + 1 - m)
			count += 1
			sum += start
			xor_offsets ^= start
		}
	}
	return (count << 36) | (sum << 12) | xor_offsets
}

@(export)
forward_dawg_matching :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv, mv := input[0], input[1]
	if nv < 0 || nv > MAX_TEXT || mv < 1 || mv > MAX_PATTERN do return -1
	n, m := int(nv), int(mv)
	if length != c.size_t(2 + n + m) do return -1
	for index := 0; index < n + m; index += 1 {
		if input[2 + index] < 0 || input[2 + index] > 3 do return -1
	}
	var pattern: [MAX_PATTERN]i64
	for index := 0; index < m; index += 1 { pattern[index] = input[2+n+index] }
	var sam: Suffix_Automaton
	init_sam(&sam)
	last := i64(0)
	for index := 0; index < m; index += 1 {
		last = extend(&sam, last, int(pattern[index]))
		if last < 0 do return -1
	}
	return search(&sam, input, n, m)
}
