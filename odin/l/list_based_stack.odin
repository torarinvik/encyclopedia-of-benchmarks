package list_based_stack

import "core:c"

MAX_INITIAL_ITEMS :: 32
MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 162
MAX_STACK_SIZE :: 96
MAX_OUTPUT_BYTES :: 1024

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u64(8*byte))
	}
}

@(export)
list_based_stack :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_initial_count := input[0]
	if raw_initial_count < 0 || raw_initial_count > i64(MAX_INITIAL_ITEMS) do return -1
	initial_count := int(raw_initial_count)
	operation_count_index := 1 + initial_count
	if operation_count_index >= int(length) do return -1

	initial_items: [MAX_INITIAL_ITEMS]i64
	for index := 0; index < initial_count; index += 1 {
		value := input[1+index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		initial_items[index] = value
	}

	raw_operation_count := input[operation_count_index]
	if raw_operation_count < 0 || raw_operation_count > i64(MAX_OPERATIONS) do return -1
	operation_count := int(raw_operation_count)
	opcodes: [MAX_OPERATIONS]i64
	arguments: [MAX_OPERATIONS]i64
	cursor := operation_count_index + 1
	validated_size := initial_count
	for index := 0; index < operation_count; index += 1 {
		if cursor >= int(length) do return -1
		opcode := input[cursor]
		cursor += 1
		opcodes[index] = opcode
		if opcode == 1 || opcode == 5 {
			if cursor >= int(length) do return -1
			value := input[cursor]
			cursor += 1
			if value < -2_147_483_648 || value > 2_147_483_647 do return -1
			arguments[index] = value
			if opcode == 1 do validated_size += 1
		} else if opcode == 2 || opcode == 3 {
			if validated_size == 0 do return -1
			if opcode == 2 do validated_size -= 1
		} else if opcode == 4 {
			// Count leaves the stack unchanged.
		} else if opcode == 6 {
			validated_size = 0
		} else do return -1
	}
	if cursor != int(length) do return -1

	stack: [MAX_STACK_SIZE]i64
	stack_size := initial_count
	for index := 0; index < initial_count; index += 1 {
		stack[index] = initial_items[index]
	}
	buffer: [MAX_OUTPUT_BYTES]u8
	written := 0
	for index := 0; index < operation_count; index += 1 {
		opcode := opcodes[index]
		result: i64 = 0
		if opcode == 1 {
			stack[stack_size] = arguments[index]
			stack_size += 1
		} else if opcode == 2 {
			stack_size -= 1
			result = stack[stack_size]
		} else if opcode == 3 {
			result = stack[stack_size-1]
		} else if opcode == 4 {
			result = i64(stack_size)
		} else if opcode == 5 {
			for item := 0; item < stack_size; item += 1 {
				if stack[item] == arguments[index] { result = 1; break }
			}
		} else {
			stack_size = 0
		}
		put_i64_le(&buffer[0], written, opcode)
		put_i64_le(&buffer[0], written+8, result)
		written += 16
	}

	if output == nil || capacity < c.size_t(written) do return -2
	for index := 0; index < written; index += 1 do output[index] = buffer[index]
	return i64(written)
}
