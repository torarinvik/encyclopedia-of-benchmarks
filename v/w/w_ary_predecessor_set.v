// 64-ary hierarchical bitmap predecessor set.
module w_ary_predecessor_set

struct WarySet {
mut:
	leaf [4096]u64
	group [64]u64
	top u64
}

fn wary_low_bit(bits u64) int {
	mut low := 0
	mut high := 64
	for high - low > 1 {
		middle := (low + high) / 2
		mask := (u64(1) << middle) - 1
		if bits & mask != 0 { high = middle } else { low = middle }
	}
	return low
}

fn wary_high_bit(bits u64) int {
	mut low := 0
	mut high := 64
	for high - low > 1 {
		middle := (low + high) / 2
		if bits >> middle != 0 { low = middle } else { high = middle }
	}
	return low
}

fn wary_insert(mut state WarySet, key int) i64 {
	word := key >> 6
	bit_index := key & 63
	bit := u64(1) << bit_index
	old := state.leaf[word]
	if old & bit != 0 { return 0 }
	if old == 0 {
		group_index := word >> 6
		slot := word & 63
		if state.group[group_index] == 0 { state.top |= u64(1) << group_index }
		state.group[group_index] |= u64(1) << slot
	}
	state.leaf[word] = old | bit
	return 1
}

fn wary_erase(mut state WarySet, key int) i64 {
	word := key >> 6
	bit_index := key & 63
	bit := u64(1) << bit_index
	old := state.leaf[word]
	if old & bit == 0 { return 0 }
	state.leaf[word] = old & ~bit
	if state.leaf[word] == 0 {
		group_index := word >> 6
		slot := word & 63
		state.group[group_index] &= ~(u64(1) << slot)
		if state.group[group_index] == 0 { state.top &= ~(u64(1) << group_index) }
	}
	return 1
}

fn wary_successor(state &WarySet, key int) i64 {
	word := key >> 6
	bit_index := key & 63
	candidates := state.leaf[word] >> bit_index
	if candidates != 0 { return i64(word * 64 + bit_index + wary_low_bit(candidates) + 1) }
	group_index := word >> 6
	slot := word & 63
	mut later := u64(0)
	if slot < 63 { later = state.group[group_index] >> (slot + 1) }
	mut next_word := 0
	if later != 0 {
		next_word = group_index * 64 + slot + 1 + wary_low_bit(later)
	} else {
		if group_index < 63 { later = state.top >> (group_index + 1) } else { later = 0 }
		if later == 0 { return 0 }
		next_group := group_index + 1 + wary_low_bit(later)
		next_word = next_group * 64 + wary_low_bit(state.group[next_group])
	}
	return i64(next_word * 64 + wary_low_bit(state.leaf[next_word]) + 1)
}

fn wary_predecessor(state &WarySet, key int) i64 {
	word := key >> 6
	bit_index := key & 63
	candidates := state.leaf[word] & ((u64(1) << bit_index) - 1)
	if candidates != 0 { return i64(word * 64 + wary_high_bit(candidates) + 1) }
	group_index := word >> 6
	slot := word & 63
	mut earlier := state.group[group_index] & ((u64(1) << slot) - 1)
	mut previous_word := 0
	if earlier != 0 {
		previous_word = group_index * 64 + wary_high_bit(earlier)
	} else {
		earlier = state.top & ((u64(1) << group_index) - 1)
		if earlier == 0 { return 0 }
		previous_group := wary_high_bit(earlier)
		previous_word = previous_group * 64 + wary_high_bit(state.group[previous_group])
	}
	return i64(previous_word * 64 + wary_high_bit(state.leaf[previous_word]) + 1)
}

@[export: 'w_ary_predecessor_set']
pub fn w_ary_predecessor_set(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 66 { return -1 }
		q_value := input[0]
		if q_value < 0 || q_value > 32 { return -1 }
		q := int(q_value)
		if length != usize(1 + 2 * q) { return -1 }
		mut state := WarySet{}
		mut result := i64(0)
		mut cursor := 1
		for operation in 0 .. q {
			opcode := input[cursor]
			raw_key := input[cursor + 1]
			cursor += 2
			if opcode < 0 || opcode > 4 || raw_key < 0 || raw_key >= 262144 { return -1 }
			key := int(raw_key)
			mut answer := i64(0)
			if opcode == 0 {
				answer = wary_insert(mut state, key)
			} else if opcode == 1 {
				answer = wary_erase(mut state, key)
			} else if opcode == 2 {
				if state.leaf[key >> 6] & (u64(1) << (key & 63)) != 0 { answer = 1 }
			} else if opcode == 3 {
				answer = wary_successor(&state, key)
			} else {
				answer = wary_predecessor(&state, key)
			}
			result += i64(operation + 1) * answer
		}
		return result
	}
}
