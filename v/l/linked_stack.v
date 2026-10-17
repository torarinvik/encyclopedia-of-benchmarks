module linked_stack

const max_operations = 64
const max_input_length = 129
const max_output_bytes = 1536

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn put_record(mut output &u8, offset int, opcode i64, tag i64, value i64) {
	put_i64_le(mut output, offset, opcode)
	put_i64_le(mut output, offset + 8, tag)
	put_i64_le(mut output, offset + 16, value)
}

@[export: 'linked_stack']
pub fn linked_stack(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		raw_count := input[0]
		if raw_count < 0 || raw_count > max_operations { return -1 }
		operation_count := int(raw_count)
		mut opcodes := [max_operations]i64{init: 0}
		mut arguments := [max_operations]i64{init: 0}
		mut cursor := 1
		for index := 0; index < operation_count; index++ {
			if cursor >= int(length) { return -1 }
			opcode := input[cursor]
			cursor++
			opcodes[index] = opcode
			if opcode == 1 {
				if cursor >= int(length) { return -1 }
				value := input[cursor]
				cursor++
				if value < -2147483648 || value > 2147483647 { return -1 }
				arguments[index] = value
			} else if opcode < 2 || opcode > 4 {
				return -1
			}
		}
		if cursor != int(length) { return -1 }

		mut node_values := [max_operations + 1]i64{init: 0}
		mut below := [max_operations + 1]int{init: 0}
		mut node_count := 0
		mut head := 0
		mut buffer := [max_output_bytes]u8{init: 0}
		mut written := 0
		for index := 0; index < operation_count; index++ {
			opcode := opcodes[index]
			mut tag := i64(2)
			mut value := i64(0)
			if opcode == 1 {
				node_count++
				node_values[node_count] = arguments[index]
				below[node_count] = head
				head = node_count
			} else if opcode == 2 {
				if head != 0 {
					tag = 0
					value = node_values[head]
				}
			} else if opcode == 3 {
				if head != 0 {
					tag = 0
					value = node_values[head]
					head = below[head]
				}
			} else {
				tag = 1
				value = if head == 0 { 1 } else { 0 }
			}
			put_record(mut buffer[0], written, opcode, tag, value)
			written += 24
		}

		if output == nil || capacity < usize(written) { return -2 }
		for index := 0; index < written; index++ { output[index] = buffer[index] }
		return i64(written)
	}
}
