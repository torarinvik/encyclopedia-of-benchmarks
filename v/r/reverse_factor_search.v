module reverse_factor_search

const max_text = 4096
const max_pattern = 128
const max_input_length = 4227
const max_states = 2 * max_pattern + 1

@[export: 'reverse_factor_search']
pub fn reverse_factor_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 0 || n64 > max_text || m64 < 1 || m64 > max_pattern { return -1 }
		n, m := int(n64), int(m64)
		if int(length) != 2+n+m { return -1 }
		mut text := [max_text]u8{}
		mut pattern := [max_pattern]u8{}
		for q in 0 .. n {
			value := input[2+q]
			if value < 0 || value > 3 { return -1 }
			text[q] = u8(value)
		}
		for q in 0 .. m {
			value := input[2+n+q]
			if value < 0 || value > 3 { return -1 }
			pattern[q] = u8(value)
		}
		if n < m { return 0 }

		mut transitions := [max_states*4]int{init: -1}
		mut suffix_link := [max_states]int{init: -1}
		mut max_length := [max_states]int{}
		mut terminal := [max_states]bool{}
		mut state_count := 1
		mut last := 0
		for pos in 0 .. m {
			symbol := int(pattern[m-1-pos])
			current := state_count
			state_count++
			max_length[current] = max_length[last] + 1
			mut predecessor := last
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
					state_count++
					for symbol_index in 0 .. 4 {
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
		mut terminal_state := last
		for terminal_state >= 0 {
			terminal[terminal_state] = true
			terminal_state = suffix_link[terminal_state]
		}

		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		mut period := m
		mut start := 0
		for start <= n-m {
			mut index := m-1
			mut state := 0
			mut shift := m
			for start+index >= 0 {
				target := transitions[state*4+int(text[start+index])]
				if target < 0 { break }
				state = target
				if terminal[state] {
					period = shift
					shift = index
				}
				index--
			}
			if index < 0 {
				count++
				offset_sum += i64(start)
				offset_xor ^= i64(start)
				shift = period
			}
			start += shift
		}
		return (count << 36) | (offset_sum << 12) | offset_xor
	}
}
