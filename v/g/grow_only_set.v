module grow_only_set

@[export: 'grow_only_set']
pub fn grow_only_set(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 25 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > 12 || length != usize(1 + 2 * count_value) { return -1 }
	mut left := u64(0)
	mut right := u64(0)
	mut answers := u64(0)
	mut query_count := 0
	for index in 0 .. int(count_value) {
		opcode := unsafe { values[1 + 2 * index] }
		argument := unsafe { values[2 + 2 * index] }
		if opcode < 0 || opcode > 7 { return -1 }
		if opcode <= 3 {
			if argument < 0 || argument > 15 { return -1 }
		} else if argument != 0 { return -1 }
		bit := if opcode <= 3 { u64(1) << u64(argument) } else { u64(0) }
		if opcode == 0 { left |= bit }
		else if opcode == 1 { right |= bit }
		else if opcode == 2 {
			if (left & bit) != 0 { answers |= u64(1) << query_count }
			query_count++
		} else if opcode == 3 {
			if (right & bit) != 0 { answers |= u64(1) << query_count }
			query_count++
		} else if opcode == 4 {
			if (left & right) == left { answers |= u64(1) << query_count }
			query_count++
		} else if opcode == 5 {
			if (left & right) == right { answers |= u64(1) << query_count }
			query_count++
		} else if opcode == 6 { left |= right }
		else { right |= left }
	}
	return i64(answers | (left << 12) | (right << 28) | (u64(query_count) << 44))
}
