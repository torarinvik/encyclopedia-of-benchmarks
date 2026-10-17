module list_based_stack

const max_initial_items = 32
const max_operations = 64
const max_input_length = 162
const max_stack_size = 96
const max_output_bytes = 1024

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'list_based_stack']
pub fn list_based_stack(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		raw_initial_count := input[0]
		if raw_initial_count < 0 || raw_initial_count > max_initial_items { return -1 }
		initial_count := int(raw_initial_count)
		operation_count_index := 1 + initial_count
		if operation_count_index >= int(length) { return -1 }

		mut initial_items := [max_initial_items]i64{init: 0}
		for index := 0; index < initial_count; index++ {
			value := input[1 + index]
			if value < -2147483648 || value > 2147483647 { return -1 }
			initial_items[index] = value
		}

		raw_operation_count := input[operation_count_index]
		if raw_operation_count < 0 || raw_operation_count > max_operations { return -1 }
		operation_count := int(raw_operation_count)
		mut opcodes := [max_operations]i64{init: 0}
		mut arguments := [max_operations]i64{init: 0}
		mut cursor := operation_count_index + 1
		mut validated_size := initial_count
		for index := 0; index < operation_count; index++ {
			if cursor >= int(length) { return -1 }
			opcode := input[cursor]
			cursor++
			opcodes[index] = opcode
			if opcode == 1 || opcode == 5 {
				if cursor >= int(length) { return -1 }
				value := input[cursor]
				cursor++
				if value < -2147483648 || value > 2147483647 { return -1 }
				arguments[index] = value
				if opcode == 1 { validated_size++ }
			} else if opcode == 2 || opcode == 3 {
				if validated_size == 0 { return -1 }
				if opcode == 2 { validated_size-- }
			} else if opcode == 4 {
				// Count leaves the stack unchanged.
			} else if opcode == 6 {
				validated_size = 0
			} else {
				return -1
			}
		}
		if cursor != int(length) { return -1 }

		mut stack := [max_stack_size]i64{init: 0}
		mut stack_size := initial_count
		for index := 0; index < initial_count; index++ { stack[index] = initial_items[index] }
		mut buffer := [max_output_bytes]u8{init: 0}
		mut written := 0
		for index := 0; index < operation_count; index++ {
			opcode := opcodes[index]
			mut result := i64(0)
			if opcode == 1 {
				stack[stack_size] = arguments[index]
				stack_size++
			} else if opcode == 2 {
				stack_size--
				result = stack[stack_size]
			} else if opcode == 3 {
				result = stack[stack_size - 1]
			} else if opcode == 4 {
				result = i64(stack_size)
			} else if opcode == 5 {
				for item := 0; item < stack_size; item++ {
					if stack[item] == arguments[index] { result = 1; break }
				}
			} else {
				stack_size = 0
			}
			put_i64_le(mut buffer[0], written, opcode)
			put_i64_le(mut buffer[0], written + 8, result)
			written += 16
		}

		if output == nil || capacity < usize(written) { return -2 }
		for index := 0; index < written; index++ { output[index] = buffer[index] }
		return i64(written)
	}
}
