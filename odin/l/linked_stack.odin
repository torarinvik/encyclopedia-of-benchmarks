package linked_stack

import "core:c"

MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 129
MAX_OUTPUT_BYTES :: 1536

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u64(8*byte))
	}
}

put_record :: proc "contextless" (output: [^]u8, offset: int, opcode, tag, value: i64) {
	put_i64_le(output, offset, opcode)
	put_i64_le(output, offset+8, tag)
	put_i64_le(output, offset+16, value)
}

@(export)
linked_stack :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > i64(MAX_OPERATIONS) do return -1
	operation_count := int(raw_count)
	opcodes: [MAX_OPERATIONS]i64
	arguments: [MAX_OPERATIONS]i64
	cursor := 1
	for index := 0; index < operation_count; index += 1 {
		if cursor >= int(length) do return -1
		opcode := input[cursor]
		cursor += 1
		opcodes[index] = opcode
		if opcode == 1 {
			if cursor >= int(length) do return -1
			value := input[cursor]
			cursor += 1
			if value < -2_147_483_648 || value > 2_147_483_647 do return -1
			arguments[index] = value
		} else if opcode < 2 || opcode > 4 do return -1
	}
	if cursor != int(length) do return -1

	node_values: [MAX_OPERATIONS+1]i64
	below: [MAX_OPERATIONS+1]int
	node_count, head := 0, 0
	buffer: [MAX_OUTPUT_BYTES]u8
	written := 0
	for index := 0; index < operation_count; index += 1 {
		opcode := opcodes[index]
		tag, value: i64 = 2, 0
		if opcode == 1 {
			node_count += 1
			node_values[node_count] = arguments[index]
			below[node_count] = head
			head = node_count
		} else if opcode == 2 {
			if head != 0 { tag = 0; value = node_values[head] }
		} else if opcode == 3 {
			if head != 0 { tag = 0; value = node_values[head]; head = below[head] }
		} else {
			tag = 1
			if head == 0 do value = 1
		}
		put_record(&buffer[0], written, opcode, tag, value)
		written += 24
	}

	if output == nil || capacity < c.size_t(written) do return -2
	for index := 0; index < written; index += 1 do output[index] = buffer[index]
	return i64(written)
}
