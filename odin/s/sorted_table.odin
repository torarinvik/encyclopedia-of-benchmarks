package sorted_table

import "core:c"

MAX_INITIAL_KEYS :: 128
MAX_OPERATIONS :: 256
MAX_SIZE :: 256
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(899)
MIN_KEY :: i64(-1_000_000)
MAX_KEY :: i64(1_000_000)
HASH_MODULUS :: i64(1_000_000_007)

lower_bound :: proc "contextless" (items: [^]i64, count: int, key: i64) -> int {
	left, right := 0, count
	for left < right {
		middle := left + (right-left)/2
		if items[middle] < key { left = middle+1 } else { right = middle }
	}
	return left
}

upper_bound :: proc "contextless" (items: [^]i64, count: int, key: i64) -> int {
	left, right := 0, count
	for left < right {
		middle := left + (right-left)/2
		if items[middle] <= key { left = middle+1 } else { right = middle }
	}
	return left
}

key_code :: proc "contextless" (key: i64) -> i64 { return key-MIN_KEY+1 }

sequence_code :: proc "contextless" (items: [^]i64, start, end: int, descending: bool) -> i64 {
	hash := i64(0)
	if descending {
		for index := end-1; index >= start; index -= 1 { hash = (31*hash+key_code(items[index]))%HASH_MODULUS }
	} else {
		for index in start ..< end { hash = (31*hash+key_code(items[index]))%HASH_MODULUS }
	}
	return i64(end-start)*HASH_MODULUS+hash
}

sorted_table_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	initial_value := input[0]
	if initial_value < 0 || initial_value > MAX_INITIAL_KEYS do return -1
	initial_count := int(initial_value)
	operation_count_index := initial_count+1
	if c.size_t(operation_count_index) >= length do return -1
	operation_value := input[operation_count_index]
	if operation_value < 0 || operation_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_value)
	if length != c.size_t(operation_count_index+1+3*operation_count) || length > 898 do return -1

	var items: [MAX_SIZE]i64
	count := initial_count
	for index in 0 ..< initial_count {
		key := input[index+1]
		if key < MIN_KEY || key > MAX_KEY || (index > 0 && items[index-1] >= key) do return -1
		items[index] = key
	}

	checksum := i64(0)
	operations_start := operation_count_index+1
	for operation in 0 ..< operation_count {
		position := operations_start+3*operation
		opcode, first, second := input[position], input[position+1], input[position+2]
		observed := i64(0)
		has_result := true
		if opcode == 0 || opcode == 1 || opcode == 4 || opcode == 5 || opcode == 7 {
			if second != 0 || first < MIN_KEY || first > MAX_KEY do return -1
			at := lower_bound(&items[0], count, first)
			found := at < count && items[at] == first
			if opcode == 0 { if found { observed = key_code(first) }
			} else if opcode == 1 { if found { observed = 1 }
			} else if opcode == 4 {
				next := at
				if found { next += 1 }
				if next < count { observed = key_code(items[next]) }
			} else if opcode == 5 {
				if at > 0 { observed = key_code(items[at-1]) }
			} else if found {
				for index := at; index+1 < count; index += 1 { items[index] = items[index+1] }
				count -= 1
				observed = key_code(first)
			}
		} else if opcode == 2 || opcode == 3 {
			if first != 0 || second != 0 do return -1
			if count > 0 { if opcode == 2 { observed = key_code(items[0]) } else { observed = key_code(items[count-1]) } }
		} else if opcode == 6 {
			if first < MIN_KEY || first > MAX_KEY || (second != 0 && second != 1) do return -1
			at := lower_bound(&items[0], count, first)
			if at < count && items[at] == first { observed = key_code(items[at])
			} else {
				if count >= MAX_SIZE do return -1
				for index := count; index > at; index -= 1 { items[index] = items[index-1] }
				items[at] = first
				count += 1
			}
		} else if opcode == 8 || opcode == 9 {
			if first < MIN_KEY || first > MAX_KEY || second < MIN_KEY || second > MAX_KEY do return -1
			start, end := 0, 0
			if first <= second { start = lower_bound(&items[0], count, first); end = upper_bound(&items[0], count, second) }
			observed = sequence_code(&items[0], start, end, opcode == 9)
		} else if opcode == 10 || opcode == 11 {
			if first != 0 || second != 0 do return -1
			observed = sequence_code(&items[0], 0, count, opcode == 11)
		} else if opcode == 12 {
			if first != 0 || second != 0 do return -1
			if count == 0 { observed = 1 }
		} else if opcode == 13 {
			if first != 0 || second != 0 do return -1
			count = 0
			has_result = false
		} else { return -1 }
		if has_result { checksum += i64(operation+1)*(observed+1) }
	}
	for index in 0 ..< count { checksum += i64(operation_count+index+1)*key_code(items[index]) }
	return checksum
}
