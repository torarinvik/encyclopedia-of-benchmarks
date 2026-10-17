module linked_list_stack

const max_operations = 64
const max_input_length = 129
const max_depth = 64
const max_output_bytes = 516

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'linked_list_stack']
pub fn linked_list_stack(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		if input[0] < 0 || input[0] > max_operations { return -1 }

		operation_count := int(input[0])
		input_length := int(length)
		mut node_values := [max_depth]i32{}
		mut node_next := [max_depth]i32{}
		mut records := [2 * max_operations]i32{}
		mut node_count := 0
		mut query_count := 0
		mut cursor := 1
		mut top := i32(-1)
		mut stack_size := i32(0)
		for _ in 0 .. operation_count {
			if cursor >= input_length { return -1 }
			opcode := input[cursor]
			cursor++
			if opcode == 0 {
				if cursor >= input_length { return -1 }
				value := input[cursor]
				cursor++
				if value < -2147483648 || value > 2147483647 || stack_size >= i32(max_depth) || node_count >= max_depth { return -1 }
				node_values[node_count] = i32(value)
				node_next[node_count] = top
				top = i32(node_count)
				node_count++
				stack_size++
			} else if opcode == 1 {
				if stack_size == 0 || top < 0 { return -1 }
				records[2 * query_count] = 1
				records[2 * query_count + 1] = node_values[int(top)]
				query_count++
				top = node_next[int(top)]
				stack_size--
			} else if opcode == 2 {
				records[2 * query_count] = 2
				records[2 * query_count + 1] = stack_size
				query_count++
			} else if opcode == 3 {
				records[2 * query_count] = 3
				records[2 * query_count + 1] = if stack_size == 0 { 1 } else { 0 }
				query_count++
			} else {
				return -1
			}
		}
		if cursor != input_length { return -1 }

		output_bytes := 4 + 8 * query_count
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		put_i32_le(mut buffer[0], 0, i32(query_count))
		for index in 0 .. 2 * query_count {
			put_i32_le(mut buffer[0], 4 + 4 * index, records[index])
		}
		for byte in 0 .. output_bytes { output[byte] = buffer[byte] }
		return i64(output_bytes)
	}
}
