const max_text = 4096
const max_pattern = 128
const max_input = 4227
const max_states = 2 * max_pattern + 2

@[export: 'forward_dawg_matching']
pub fn forward_dawg_matching(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		nv, mv := input[0], input[1]
		if nv < 0 || nv > max_text || mv < 1 || mv > max_pattern { return -1 }
		n, m := int(nv), int(mv)
		if length != usize(2 + n + m) { return -1 }
		for i in 0 .. n + m {
			if input[2 + i] < 0 || input[2 + i] > 3 { return -1 }
		}

		mut pattern := [max_pattern]i64{}
		for i in 0 .. m { pattern[i] = input[2 + n + i] }
		mut transition := [max_states][4]i64{}
		mut suffix_link := [max_states]i64{}
		mut max_length := [max_states]i64{}
		for state in 0 .. max_states {
			suffix_link[state] = -1
			for symbol in 0 .. 4 { transition[state][symbol] = -1 }
		}
		mut state_count := 1
		mut last := 0
		for index in 0 .. m {
			if state_count >= max_states { return -1 }
			current := state_count
			state_count++
			symbol := int(pattern[index])
			max_length[current] = max_length[last] + 1
			mut state := last
			for state >= 0 && transition[state][symbol] < 0 {
				transition[state][symbol] = i64(current)
				state = int(suffix_link[state])
			}
			if state < 0 {
				suffix_link[current] = 0
			} else {
				target := transition[state][symbol]
				if max_length[state] + 1 == max_length[int(target)] {
					suffix_link[current] = target
				} else {
					if state_count >= max_states { return -1 }
					clone := state_count
					state_count++
					max_length[clone] = max_length[state] + 1
					suffix_link[clone] = suffix_link[int(target)]
					for c in 0 .. 4 { transition[clone][c] = transition[int(target)][c] }
					for state >= 0 && transition[state][symbol] == target {
						transition[state][symbol] = i64(clone)
						state = int(suffix_link[state])
					}
					suffix_link[int(target)] = i64(clone)
					suffix_link[current] = i64(clone)
				}
			}
			last = current
		}

		mut state := 0
		mut matched := i64(0)
		mut count := i64(0)
		mut offset_sum := i64(0)
		mut offset_xor := i64(0)
		for position in 0 .. n {
			symbol := int(input[2 + position])
			mut target := transition[state][symbol]
			if target >= 0 {
				matched++
				state = int(target)
			} else {
				for state != 0 && transition[state][symbol] < 0 {
					state = int(suffix_link[state])
				}
				target = transition[state][symbol]
				if target >= 0 {
					matched = max_length[state] + 1
					state = int(target)
				} else {
					matched = 0
					state = 0
				}
			}
			if matched == i64(m) {
				start := i64(position + 1 - m)
				count++
				offset_sum += start
				offset_xor ^= start
			}
		}
		return (count << 36) | (offset_sum << 12) | offset_xor
	}
}
