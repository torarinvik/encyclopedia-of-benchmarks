package grow_only_set

import "core:c"

@(export)
grow_only_set :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 25 do return -1
	count_value := values[0]
	if count_value < 0 || count_value > 12 || length != c.size_t(1 + 2 * count_value) do return -1
	left: u64 = 0
	right: u64 = 0
	answers: u64 = 0
	query_count := 0
	for index := 0; index < int(count_value); index += 1 {
		opcode, argument := values[1 + 2 * index], values[2 + 2 * index]
		if opcode < 0 || opcode > 7 do return -1
		if opcode <= 3 {
			if argument < 0 || argument > 15 do return -1
		} else if argument != 0 do return -1
		bit: u64 = 0
		if opcode <= 3 do bit = u64(1) << u64(argument)
		if opcode == 0 do left |= bit
		else if opcode == 1 do right |= bit
		else if opcode == 2 {
			if (left & bit) != 0 do answers |= u64(1) << u64(query_count)
			query_count += 1
		} else if opcode == 3 {
			if (right & bit) != 0 do answers |= u64(1) << u64(query_count)
			query_count += 1
		} else if opcode == 4 {
			if (left & right) == left do answers |= u64(1) << u64(query_count)
			query_count += 1
		} else if opcode == 5 {
			if (left & right) == right do answers |= u64(1) << u64(query_count)
			query_count += 1
		} else if opcode == 6 do left |= right
		else do right |= left
	}
	return i64(answers | (left << 12) | (right << 28) | (u64(query_count) << 44))
}
