package linked_list_stack

import "core:c"

MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 129
MAX_DEPTH :: 64
MAX_OUTPUT_BYTES :: 516

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits >> u32(8*byte))
	}
}

@(export)
linked_list_stack :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return -1

	operation_count := int(input[0])
	node_values: [MAX_DEPTH]i32
	node_next: [MAX_DEPTH]i32
	records: [2*MAX_OPERATIONS]i32
	node_count, query_count, cursor := 0, 0, 1
	top: i32 = -1
	stack_size: i32 = 0
	for operation := 0; operation < operation_count; operation += 1 {
		if cursor >= int(length) do return -1
		opcode := input[cursor]
		cursor += 1
		if opcode == 0 {
			if cursor >= int(length) do return -1
			value := input[cursor]
			cursor += 1
			if value < -2_147_483_648 || value > 2_147_483_647 ||
				stack_size >= i32(MAX_DEPTH) || node_count >= MAX_DEPTH do return -1
			node_values[node_count] = i32(value)
			node_next[node_count] = top
			top = i32(node_count)
			node_count += 1
			stack_size += 1
		} else if opcode == 1 {
			if stack_size == 0 || top < 0 do return -1
			records[2*query_count] = 1
			records[2*query_count+1] = node_values[int(top)]
			query_count += 1
			top = node_next[int(top)]
			stack_size -= 1
		} else if opcode == 2 {
			records[2*query_count] = 2
			records[2*query_count+1] = stack_size
			query_count += 1
		} else if opcode == 3 {
			records[2*query_count] = 3
			if stack_size == 0 do records[2*query_count+1] = 1
			else do records[2*query_count+1] = 0
			query_count += 1
		} else {
			return -1
		}
	}
	if cursor != int(length) do return -1

	output_bytes := 4 + 8*query_count
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	buffer: [MAX_OUTPUT_BYTES]u8
	put_i32_le(&buffer[0], 0, i32(query_count))
	for index := 0; index < 2*query_count; index += 1 {
		put_i32_le(&buffer[0], 4+4*index, records[index])
	}
	for byte := 0; byte < output_bytes; byte += 1 do output[byte] = buffer[byte]
	return i64(output_bytes)
}
