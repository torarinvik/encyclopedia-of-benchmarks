const max_text = 4096
const max_pattern = 128
const max_input = 4227
const max_states = 2 * max_pattern + 2
const root = 0
const artificial = 1

struct Automaton {
	mut:
	transition [max_states][4]i64
	displacement [max_states][4]i64
	suffix_link [max_states]i64
	max_length [max_states]i64
	position [max_states]i64
	terminal [max_states]i64
	state_count int
}

fn (mut aut Automaton) init() {
	aut.state_count = 2
	for state in 0 .. max_states {
		aut.suffix_link[state] = -1
		for symbol in 0 .. 4 {
			aut.transition[state][symbol] = -1
			aut.displacement[state][symbol] = 0
		}
	}
	aut.suffix_link[root] = i64(artificial)
}

fn (mut aut Automaton) build(pattern [max_pattern]i64, m int) bool {
	mut last := root
	for offset in 0 .. m {
		symbol := int(pattern[m - 1 - offset])
		if aut.state_count >= max_states { return false }
		current := aut.state_count
		aut.state_count++
		aut.max_length[current] = aut.max_length[last] + 1
		aut.position[current] = aut.position[last] + 1
		mut state := last
		for state != root && aut.transition[state][symbol] < 0 {
			aut.transition[state][symbol] = i64(current)
			aut.displacement[state][symbol] = aut.position[current] - aut.position[state] - 1
			state = int(aut.suffix_link[state])
		}
		target := aut.transition[state][symbol]
		if target < 0 {
			aut.transition[root][symbol] = i64(current)
			aut.displacement[root][symbol] = aut.position[current] - aut.position[root] - 1
			aut.suffix_link[current] = i64(root)
		} else if aut.max_length[state] + 1 == aut.max_length[int(target)] {
			aut.suffix_link[current] = target
		} else {
			if aut.state_count >= max_states { return false }
			clone := aut.state_count
			aut.state_count++
			aut.transition[clone] = aut.transition[int(target)]
			aut.displacement[clone] = aut.displacement[int(target)]
			aut.suffix_link[clone] = aut.suffix_link[int(target)]
			aut.max_length[clone] = aut.max_length[state] + 1
			aut.position[clone] = aut.position[int(target)]
			aut.terminal[clone] = aut.terminal[int(target)]
			aut.suffix_link[int(target)] = i64(clone)
			aut.suffix_link[current] = i64(clone)
			for state != artificial {
				old_target := aut.transition[state][symbol]
				if old_target < 0 || aut.max_length[int(old_target)] < aut.max_length[clone] { break }
				aut.displacement[state][symbol] = aut.position[int(old_target)] - aut.position[state] - 1
				aut.transition[state][symbol] = i64(clone)
				state = int(aut.suffix_link[state])
			}
		}
		last = current
	}
	aut.terminal[last] = 1
	for last != root {
		last = int(aut.suffix_link[last])
		aut.terminal[last] = 1
	}
	return true
}

fn mp_next(pattern [max_pattern]i64, m int, mut next [max_pattern + 1]i64) {
	mut i := i64(0)
	mut border := i64(-1)
	next[0] = -1
	for i < i64(m) {
		for border >= 0 && pattern[int(i)] != pattern[int(border)] {
			border = next[int(border)]
		}
		i++
		border++
		next[int(i)] = border
	}
}

fn search(aut &Automaton, input &i64, n int, m int, mp [max_pattern + 1]i64) i64 {
	if n < m { return 0 }
	period := i64(m) - mp[m]
	mut count := i64(0)
	mut offset_sum := i64(0)
	mut offset_xor := i64(0)
	mut start := 0
	mut preceding_shift := i64(m)
	for start <= n - m {
		mut index := i64(m) - 1
		mut state := root
		mut boundary := i64(m) - 1 - preceding_shift
		prefix_length := i64(m) - preceding_shift
		mut prefix_period := i64(0)
		if preceding_shift != i64(m) { prefix_period = prefix_length - mp[int(prefix_length)] }
		mut shift := i64(m)
		mut displacement_sum := i64(0)
		for index > boundary {
			symbol := int(input[2 + start + int(index)])
			target := aut.transition[state][symbol]
			if target < 0 { break }
			displacement_sum += aut.displacement[state][symbol]
			state = int(target)
			if aut.terminal[state] != 0 { shift = index }
			index--
		}
		if index <= boundary {
			if displacement_sum == 0 {
				count++
				offset_sum += i64(start)
				offset_xor ^= i64(start)
				shift = period
			} else {
				half := (boundary + 1) / 2
				if prefix_period <= half {
					boundary -= prefix_period
					for index > boundary {
						symbol := int(input[2 + start + int(index)])
						target := aut.transition[state][symbol]
						if target < 0 { break }
						displacement_sum += aut.displacement[state][symbol]
						state = int(target)
						if aut.terminal[state] != 0 { shift = index }
						index--
					}
					if index <= boundary { shift = displacement_sum }
				} else {
					boundary = boundary - half - 1
					for index > boundary {
						symbol := int(input[2 + start + int(index)])
						target := aut.transition[state][symbol]
						if target < 0 { break }
						displacement_sum += aut.displacement[state][symbol]
						state = int(target)
						if aut.terminal[state] != 0 { shift = index }
						index--
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

@[export: 'turbo_reverse_factor_search']
pub fn turbo_reverse_factor_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		nv, mv := input[0], input[1]
		if nv < 0 || nv > max_text || mv < 1 || mv > max_pattern { return -1 }
		n, m := int(nv), int(mv)
		if length != usize(2 + n + m) { return -1 }
		for index in 0 .. n + m {
			if input[2 + index] < 0 || input[2 + index] > 3 { return -1 }
		}
		mut pattern := [max_pattern]i64{}
		for index in 0 .. m { pattern[index] = input[2 + n + index] }
		mut aut := Automaton{}
		aut.init()
		if !aut.build(pattern, m) { return -1 }
		mut mp := [max_pattern + 1]i64{}
		mp_next(pattern, m, mut mp)
		return search(&aut, input, n, m, mp)
	}
}
