module linkedlist_implentation_usingarray

const max_input_length = 202
const max_list_length = 100

fn write_i32_le(mut output &u8, index int, value i32) {
	unsafe {
		bits := u32(value)
		offset := index * 4
		for byte in 0 .. 4 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'linkedlist_implentation_usingarray']
pub fn linkedlist_implentation_usingarray(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		operation_count := input[0]
		if operation_count < 0 || operation_count > 100 || int(length) != 1 + 2 * int(operation_count) { return -1 }
		mut items := [max_list_length]i32{}
		mut item_count := 0
		mut cursor := 1
		for _ in 0 .. int(operation_count) {
			opcode, raw_value := input[cursor], input[cursor + 1]
			cursor += 2
			if raw_value < -2147483648 || raw_value > 2147483647 || item_count >= max_list_length { return -1 }
			value := i32(raw_value)
			if opcode == 0 {
				for index := item_count; index > 0; index-- { items[index] = items[index - 1] }
				items[0] = value
				item_count++
			} else if opcode == 1 {
				if item_count == 0 { return -1 }
				items[item_count] = value
				item_count++
			} else {
				return -1
			}
		}
		output_bytes := (item_count + 1) * 4
		if output == nil || capacity < usize(output_bytes) { return -2 }
		write_i32_le(mut output, 0, i32(item_count))
		for index in 0 .. item_count { write_i32_le(mut output, index + 1, items[index]) }
		return i64(output_bytes)
	}
}
