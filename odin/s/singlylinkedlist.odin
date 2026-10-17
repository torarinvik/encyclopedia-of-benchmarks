package singlylinkedlist

import "core:c"

MAX_NODES :: 96
MAX_INPUT_VALUES :: 227

List :: struct {
	values: [MAX_NODES]i64,
	next: [MAX_NODES]int,
	used, head, tail, length: int,
}

new_list :: proc() -> List {
	list: List
	list.head = -1
	list.tail = -1
	for node := 0; node < MAX_NODES; node += 1 { list.next[node] = -1 }
	return list
}

allocate :: proc(list: ^List, value: i64) -> int {
	node := list.used
	list.used += 1
	list.values[node] = value
	list.next[node] = -1
	return node
}

add_head :: proc(list: ^List, value: i64) {
	node := allocate(list, value)
	list.next[node] = list.head
	if list.head < 0 do list.tail = node
	list.head = node
	list.length += 1
}

add_tail :: proc(list: ^List, value: i64) {
	node := allocate(list, value)
	if list.tail < 0 { list.head = node
	} else { list.next[list.tail] = node }
	list.tail = node
	list.length += 1
}

delete_head :: proc(list: ^List) -> (i64, bool) {
	if list.head < 0 do return 0, false
	node := list.head
	value := list.values[node]
	list.head = list.next[node]
	list.length -= 1
	if list.length == 0 do list.tail = -1
	return value, true
}

delete_tail :: proc(list: ^List) -> (i64, bool) {
	if list.tail < 0 do return 0, false
	value := list.values[list.tail]
	if list.length == 1 {
		list.head = -1
		list.tail = -1
	} else {
		previous := list.head
		for list.next[previous] != list.tail { previous = list.next[previous] }
		list.next[previous] = -1
		list.tail = previous
	}
	list.length -= 1
	return value, true
}

delete_position :: proc(list: ^List, position: int) -> (i64, bool) {
	if list.length == 0 do return 0, false
	if position == 1 do return delete_head(list)
	if position >= list.length do return delete_tail(list)
	previous := list.head
	for step := 1; step < position-1; step += 1 { previous = list.next[previous] }
	node := list.next[previous]
	value := list.values[node]
	list.next[previous] = list.next[node]
	list.length -= 1
	return value, true
}

reverse :: proc(list: ^List) {
	previous := -1
	current := list.head
	list.tail = list.head
	for current >= 0 {
		following := list.next[current]
		list.next[current] = previous
		previous = current
		current = following
	}
	list.head = previous
}

reverse_range :: proc(list: ^List, left, right: int) {
	before := -1
	start := list.head
	for step := 1; step < left; step += 1 { before = start; start = list.next[start] }
	previous := -1
	current := start
	for step := left; step <= right; step += 1 {
		following := list.next[current]
		list.next[current] = previous
		previous = current
		current = following
	}
	list.next[start] = current
	if before < 0 { list.head = previous
	} else { list.next[before] = previous }
	if right == list.length do list.tail = start
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
singlylinkedlist :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	initial_count_value := input[0]
	operation_count_value := input[1]
	if initial_count_value < 0 || initial_count_value > 32 || operation_count_value < 0 || operation_count_value > 64 do return -1
	initial_count := int(initial_count_value)
	operation_count := int(operation_count_value)
	if int(length) < 2+initial_count do return -1
	list := new_list()
	for i := 0; i < initial_count; i += 1 {
		value := input[2+i]
		if value < -1_000_000 || value > 1_000_000 do return -1
		add_tail(&list, value)
	}
	results: [128]i64
	cursor := 2+initial_count
	for operation := 0; operation < operation_count; operation += 1 {
		if cursor >= int(length) do return -1
		opcode := input[cursor]
		cursor += 1
		arg1, arg2 := i64(0), i64(0)
		if opcode == 0 || opcode == 1 || opcode == 4 {
			if cursor >= int(length) do return -1
			arg1 = input[cursor]
			cursor += 1
		} else if opcode == 6 {
			if int(length)-cursor < 2 do return -1
			arg1, arg2 = input[cursor], input[cursor+1]
			cursor += 2
		} else if opcode != 2 && opcode != 3 && opcode != 5 { return -1 }
		success, value := i64(1), i64(0)
		if opcode == 0 || opcode == 1 {
			if arg1 < -1_000_000 || arg1 > 1_000_000 do return -1
			if opcode == 0 { add_head(&list, arg1)
			} else { add_tail(&list, arg1) }
		} else if opcode == 2 {
			deleted, found := delete_head(&list)
			value = deleted
			if !found do success = 0
		} else if opcode == 3 {
			deleted, found := delete_tail(&list)
			value = deleted
			if !found do success = 0
		} else if opcode == 4 {
			if list.length == 0 {
				if arg1 != 1 do return -1
				success = 0
			} else {
				if arg1 < 1 || arg1 > i64(list.length+1) do return -1
				deleted_value, found := delete_position(&list, int(arg1))
				value = deleted_value
				if !found do success = 0
			}
		} else if opcode == 5 {
			reverse(&list)
		} else {
			if arg1 < 1 || arg2 < arg1 || arg2 > i64(list.length) do return -1
			reverse_range(&list, int(arg1), int(arg2))
		}
		results[operation*2] = success
		results[operation*2+1] = value
	}
	if cursor != int(length) do return -1
	output_values := 1+list.length+1+operation_count*2
	output_bytes := output_values*8
	if output_bytes > 1808 do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	put_i64_le(output, 0, i64(list.length))
	offset := 8
	node := list.head
	for node >= 0 { put_i64_le(output, offset, list.values[node]); offset += 8; node = list.next[node] }
	put_i64_le(output, offset, i64(operation_count))
	offset += 8
	for i := 0; i < operation_count*2; i += 1 { put_i64_le(output, offset, results[i]); offset += 8 }
	return i64(output_bytes)
}
