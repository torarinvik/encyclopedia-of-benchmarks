module stack_with_singly_linked_list

const max_operations = 64
const max_input_length = usize(129)
const max_output_bytes = 1536

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn write_record(mut output &u8, offset int, opcode i64, tag i64, value i64) {
	write_i64_le(mut output, offset, opcode)
	write_i64_le(mut output, offset + 8, tag)
	write_i64_le(mut output, offset + 16, value)
}

@[export: 'stack_with_singly_linked_list']
pub fn stack_with_singly_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_operations { return -1 }
	count := int(count_value)
	mut opcodes := [max_operations]i64{}
	mut arguments := [max_operations]i64{}
	mut cursor := 1
	for i in 0 .. count {
		if cursor >= int(length) { return -1 }
		opcode := unsafe { input[cursor] }
		cursor++
		opcodes[i] = opcode
		if opcode == 1 {
			if cursor >= int(length) { return -1 }
			value := unsafe { input[cursor] }
			cursor++
			if value < -2147483648 || value > 2147483647 { return -1 }
			arguments[i] = value
		} else if opcode < 2 || opcode > 5 { return -1 }
	}
	if cursor != int(length) { return -1 }

	mut node_values := [max_operations + 1]i64{}
	mut next_ids := [max_operations + 1]int{}
	mut buffer := [max_output_bytes]u8{}
	mut node_count := 0
	mut head := 0
	mut written := 0
	for i in 0 .. count {
		opcode := opcodes[i]
		mut tag := i64(2)
		mut value := i64(0)
		if opcode == 1 {
			node_count++
			node_values[node_count] = arguments[i]
			next_ids[node_count] = head
			head = node_count
		} else if opcode == 2 || opcode == 3 {
			if head == 0 {
				write_record(mut buffer, written, opcode, 4, 2)
				written += 24
				break
			}
			tag = 0
			value = node_values[head]
			if opcode == 2 { head = next_ids[head] }
		} else if opcode == 4 {
			head = 0
		} else {
			tag = 0
			for node := head; node != 0; node = next_ids[node] { value++ }
		}
		write_record(mut buffer, written, opcode, tag, value)
		written += 24
	}
	if unsafe { output == nil } || capacity < usize(written) { return -2 }
	for i in 0 .. written { unsafe { output[i] = buffer[i] } }
	return i64(written)
}
