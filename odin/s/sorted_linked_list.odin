package sorted_linked_list

import "core:c"

MAX_INITIAL_COUNT :: 16
MAX_INPUT_LENGTH :: 20
MAX_OUTPUT_WORDS :: 18

List_Node :: struct { value: i64, next: i32 }

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
	}
}

@(export)
sorted_linked_list :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_INITIAL_COUNT do return -1
	count := int(input[0])
	if input_length != c.size_t(count + 3) do return -1

	nodes: [MAX_INITIAL_COUNT + 1]List_Node
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 || (index > 0 && input[index] >= value) do return -1
		nodes[index].value = value
		nodes[index].next = i32(if index + 1 < count do index + 1 else -1)
	}
	operation_value := input[count + 1]
	key := input[count + 2]
	if operation_value < 0 || operation_value > 2 || key < -2147483648 || key > 2147483647 do return -1
	operation := int(operation_value)
	head := if count == 0 do i32(-1) else i32(0)
	tail := if count == 0 do i32(-1) else i32(count - 1)

	if operation == 0 {
		current := head
		for current >= 0 {
			if nodes[current].value == key do return -1
			current = nodes[current].next
		}
	}

	staged: [MAX_OUTPUT_WORDS]i64
	word_count := 0
	if operation == 0 {
		new_node := i32(count)
		nodes[new_node].value = key
		nodes[new_node].next = -1
		if head < 0 { head, tail = new_node, new_node }
		else if key < nodes[head].value { nodes[new_node].next = head; head = new_node }
		else if key > nodes[tail].value { nodes[tail].next = new_node; tail = new_node }
		else {
			previous := head
			for nodes[previous].next >= 0 && nodes[nodes[previous].next].value < key {
				previous = nodes[previous].next
			}
			nodes[new_node].next = nodes[previous].next
			nodes[previous].next = new_node
			if nodes[new_node].next < 0 do tail = new_node
		}
		staged[word_count] = i64(count + 1)
		word_count += 1
		for node := head; node >= 0; node = nodes[node].next { staged[word_count] = nodes[node].value; word_count += 1 }
	} else if operation == 1 {
		found: i64 = 0
		for node := head; node >= 0; node = nodes[node].next {
			if nodes[node].value == key { found = 1; break }
		}
		staged[word_count] = found
		word_count += 1
	} else {
		deleted: i64 = 0
		if head >= 0 && nodes[head].value == key {
			head = nodes[head].next
			if head < 0 do tail = -1
			deleted = 1
		} else {
			previous := head
			for previous >= 0 && nodes[previous].next >= 0 {
				candidate := nodes[previous].next
				if nodes[candidate].value == key {
					nodes[previous].next = nodes[candidate].next
					if tail == candidate do tail = previous
					deleted = 1
					break
				}
				previous = candidate
			}
		}
		staged[word_count] = deleted
		word_count += 1
		remaining := 0
		for node := head; node >= 0; node = nodes[node].next { remaining += 1 }
		staged[word_count] = i64(remaining)
		word_count += 1
		for node := head; node >= 0; node = nodes[node].next { staged[word_count] = nodes[node].value; word_count += 1 }
	}

	output_bytes := word_count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < word_count; index += 1 { put_i64_le(output, index * 8, staged[index]) }
	return i64(output_bytes)
}
