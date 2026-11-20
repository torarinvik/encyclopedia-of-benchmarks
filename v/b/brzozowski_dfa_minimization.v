module brzozowski_dfa_minimization

const max_states = 3
const first_subsets = 1 << max_states
const second_subsets = 1 << first_subsets

@[export: 'brzozowski_dfa_minimization']
pub fn brzozowski_dfa_minimization(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 10 { return -1 }
	unsafe {
		n64 := input[0]
		start64 := input[1]
		accepting64 := input[2]
		if n64 < 1 || n64 > max_states || start64 < 0 || start64 >= n64 || accepting64 < 0 || accepting64 >= (i64(1) << n64) { return -1 }
		n := int(n64)
		if length != usize(3 + 2 * n) { return -1 }
		start := int(start64)
		mut transitions := [max_states][2]int{}
		for state in 0 .. n {
			for symbol in 0 .. 2 {
				target := input[3 + 2 * state + symbol]
				if target < 0 || target >= n64 { return -1 }
				transitions[state][symbol] = int(target)
			}
		}
		mut first_masks := [first_subsets]u16{}
		mut first_delta := [first_subsets][2]int{}
		mut first_final := [first_subsets]bool{}
		mut first_id := [first_subsets]int{}
		for i in 0 .. first_subsets { first_id[i] = -1 }
		mut first_count := 1
		first_masks[0] = u16(accepting64)
		first_id[int(accepting64)] = 0
		mut cursor := 0
		for cursor < first_count {
			subset := first_masks[cursor]
			first_final[cursor] = ((subset >> start) & 1) != 0
			for symbol in 0 .. 2 {
				mut predecessor := u16(0)
				for state in 0 .. n {
					if (subset & (u16(1) << transitions[state][symbol])) != 0 { predecessor |= u16(1) << state }
				}
				mask_index := int(predecessor)
				if first_id[mask_index] < 0 { first_id[mask_index] = first_count; first_masks[first_count] = predecessor; first_count++ }
				first_delta[cursor][symbol] = first_id[mask_index]
			}
			cursor++
		}
		mut first_accepting := u16(0)
		for state in 0 .. first_count { if first_final[state] { first_accepting |= u16(1) << state } }
		mut second_queue := [second_subsets]u16{}
		mut second_seen := [second_subsets]bool{}
		mut second_count := 1
		second_queue[0] = first_accepting
		second_seen[int(first_accepting)] = true
		cursor = 0
		for cursor < second_count {
			subset := second_queue[cursor]
			for symbol in 0 .. 2 {
				mut predecessor := u16(0)
				for state in 0 .. first_count {
					if (subset & (u16(1) << first_delta[state][symbol])) != 0 { predecessor |= u16(1) << state }
				}
				mask_index := int(predecessor)
				if !second_seen[mask_index] { second_seen[mask_index] = true; second_queue[second_count] = predecessor; second_count++ }
			}
			cursor++
		}
		return i64(second_count)
	}
}
