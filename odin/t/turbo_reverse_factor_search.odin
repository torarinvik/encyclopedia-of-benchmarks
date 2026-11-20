package turbo_reverse_factor_search

import "core:c"

MAX_TEXT :: 4096
MAX_PATTERN :: 128
MAX_INPUT :: 4227
MAX_STATES :: 2 * MAX_PATTERN + 2
ROOT :: 0
ARTIFICIAL :: 1

Automaton :: struct {
	transition: [MAX_STATES][4]i64,
	displacement: [MAX_STATES][4]i64,
	suffix_link: [MAX_STATES]i64,
	max_length: [MAX_STATES]i64,
	position: [MAX_STATES]i64,
	terminal: [MAX_STATES]i64,
	state_count: int,
}

init :: proc(aut: ^Automaton) {
	aut.state_count = 2
	for state in 0..<MAX_STATES {
		aut.suffix_link[state] = -1
		aut.max_length[state] = 0
		aut.position[state] = 0
		aut.terminal[state] = 0
		for symbol in 0..<4 {
			aut.transition[state][symbol] = -1
			aut.displacement[state][symbol] = 0
		}
	}
	aut.suffix_link[ROOT] = ARTIFICIAL
}

build :: proc(aut: ^Automaton, pattern: [MAX_PATTERN]i64, m: int) -> bool {
	last := ROOT
	for offset := 0; offset < m; offset += 1 {
		symbol := int(pattern[m-1-offset])
		if aut.state_count >= MAX_STATES { return false }
		current := aut.state_count
		aut.state_count += 1
		aut.max_length[current] = aut.max_length[last] + 1
		aut.position[current] = aut.position[last] + 1
		state := i64(last)
		for state != ROOT && aut.transition[int(state)][symbol] < 0 {
			aut.transition[int(state)][symbol] = i64(current)
			aut.displacement[int(state)][symbol] =
				aut.position[current] - aut.position[int(state)] - 1
			state = aut.suffix_link[int(state)]
		}
		target := aut.transition[int(state)][symbol]
		if target < 0 {
			aut.transition[ROOT][symbol] = i64(current)
			aut.displacement[ROOT][symbol] = aut.position[current] - aut.position[ROOT] - 1
			aut.suffix_link[current] = ROOT
		} else if aut.max_length[int(state)] + 1 == aut.max_length[int(target)] {
			aut.suffix_link[current] = target
		} else {
			if aut.state_count >= MAX_STATES { return false }
			clone := aut.state_count
			aut.state_count += 1
			aut.transition[clone] = aut.transition[int(target)]
			aut.displacement[clone] = aut.displacement[int(target)]
			aut.suffix_link[clone] = aut.suffix_link[int(target)]
			aut.max_length[clone] = aut.max_length[int(state)] + 1
			aut.position[clone] = aut.position[int(target)]
			aut.terminal[clone] = aut.terminal[int(target)]
			aut.suffix_link[int(target)] = i64(clone)
			aut.suffix_link[current] = i64(clone)
			for state != ARTIFICIAL {
				old_target := aut.transition[int(state)][symbol]
				if old_target < 0 || aut.max_length[int(old_target)] < aut.max_length[clone] { break }
				aut.displacement[int(state)][symbol] =
					aut.position[int(old_target)] - aut.position[int(state)] - 1
				aut.transition[int(state)][symbol] = i64(clone)
				state = aut.suffix_link[int(state)]
			}
		}
		last = current
	}
	aut.terminal[last] = 1
	for last != ROOT {
		last = int(aut.suffix_link[last])
		aut.terminal[last] = 1
	}
	return true
}

mp_next :: proc(pattern: [MAX_PATTERN]i64, m: int, next: ^[MAX_PATTERN+1]i64) {
	i, border := i64(0), i64(-1)
	next[0] = -1
	for i < i64(m) {
		for border >= 0 && pattern[int(i)] != pattern[int(border)] {
			border = next[int(border)]
		}
		i += 1
		border += 1
		next[int(i)] = border
	}
}

search :: proc(aut: ^Automaton, input: [^]i64, n, m: int, mp: [MAX_PATTERN+1]i64) -> i64 {
	if n < m { return 0 }
	period := i64(m) - mp[m]
	count, offset_sum, offset_xor := i64(0), i64(0), i64(0)
	start := 0
	preceding_shift := i64(m)
	for start <= n-m {
		index := i64(m)-1
		state := ROOT
		boundary := i64(m)-1-preceding_shift
		prefix_length := i64(m)-preceding_shift
		prefix_period := i64(0)
		if preceding_shift != i64(m) { prefix_period = prefix_length - mp[int(prefix_length)] }
		shift, displacement_sum := i64(m), i64(0)
		for index > boundary {
			symbol := int(input[2+start+int(index)])
			target := aut.transition[state][symbol]
			if target < 0 { break }
			displacement_sum += aut.displacement[state][symbol]
			state = int(target)
			if aut.terminal[state] != 0 { shift = index }
			index -= 1
		}
		if index <= boundary {
			if displacement_sum == 0 {
				count += 1
				offset_sum += i64(start)
				offset_xor ^= i64(start)
				shift = period
			} else {
				half := (boundary+1)/2
				if prefix_period <= half {
					boundary -= prefix_period
					for index > boundary {
						symbol := int(input[2+start+int(index)])
						target := aut.transition[state][symbol]
						if target < 0 { break }
						displacement_sum += aut.displacement[state][symbol]
						state = int(target)
						if aut.terminal[state] != 0 { shift = index }
						index -= 1
					}
					if index <= boundary { shift = displacement_sum }
				} else {
					boundary = boundary-half-1
					for index > boundary {
						symbol := int(input[2+start+int(index)])
						target := aut.transition[state][symbol]
						if target < 0 { break }
						displacement_sum += aut.displacement[state][symbol]
						state = int(target)
						if aut.terminal[state] != 0 { shift = index }
						index -= 1
					}
				}
			}
		}
		if shift <= 0 { return -1 }
		start += int(shift)
		preceding_shift = shift
	}
	return (count << 36) | (offset_sum << 12) | offset_xor
}

@(export)
turbo_reverse_factor_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv, mv := input[0], input[1]
	if nv < 0 || nv > MAX_TEXT || mv < 1 || mv > MAX_PATTERN do return -1
	n, m := int(nv), int(mv)
	if length != c.size_t(2+n+m) do return -1
	for index := 0; index < n+m; index += 1 {
		if input[2+index] < 0 || input[2+index] > 3 do return -1
	}
	var pattern: [MAX_PATTERN]i64
	for index := 0; index < m; index += 1 { pattern[index] = input[2+n+index] }
	var aut: Automaton
	init(&aut)
	if !build(&aut, pattern, m) do return -1
	var mp: [MAX_PATTERN+1]i64
	mp_next(pattern, m, &mp)
	return search(&aut, input, n, m, mp)
}
