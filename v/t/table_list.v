module table_list

const max_input_length = 98
const max_output_fields = 594

fn append(mut records &i64, mut count &int, value i64) {
	unsafe {
		records[count] = value
	}
	count++
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'table_list']
pub fn table_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		operation_count := input[0]
		if operation_count < 0 || operation_count > 32 || int(length) != 1 + 3 * int(operation_count) { return -1 }
		mut items := [64]i64{}
		mut records := [max_output_fields]i64{}
		mut head := 32
		mut item_count := 0
		mut record_count := 0
		mut cursor := 1
		for _ in 0 .. int(operation_count) {
			opcode, arg1, arg2 := input[cursor], input[cursor + 1], input[cursor + 2]
			cursor += 3
			match opcode {
				0, 1 {
					if arg1 < -1000000 || arg1 > 1000000 || arg2 != 0 || item_count >= 32 { return -1 }
					if opcode == 0 { head--; items[head] = arg1 } else { items[head + item_count] = arg1 }
					item_count++
					append(mut records[0], mut record_count, opcode); append(mut records[0], mut record_count, 0)
				}
				2 {
					if arg1 != 0 || arg2 != 0 { return -1 }
					append(mut records[0], mut record_count, opcode)
					if item_count == 0 { append(mut records[0], mut record_count, 0) }
					else { append(mut records[0], mut record_count, 1); append(mut records[0], mut record_count, items[head]); head++; item_count-- }
				}
				3 {
					if arg1 != 0 || arg2 != 0 { return -1 }
					append(mut records[0], mut record_count, opcode)
					if item_count == 0 { append(mut records[0], mut record_count, 0) }
					else { append(mut records[0], mut record_count, 1); item_count--; append(mut records[0], mut record_count, items[head + item_count]) }
				}
				4, 5 {
					if arg1 != 0 || arg2 != 0 { return -1 }
					append(mut records[0], mut record_count, opcode)
					if item_count == 0 { append(mut records[0], mut record_count, 0) }
					else { append(mut records[0], mut record_count, 1); append(mut records[0], mut record_count, if opcode == 4 { items[head] } else { items[head + item_count - 1] }) }
				}
				6 {
					if arg2 != 0 || arg1 < 1 || arg1 > i64(item_count) { return -1 }
					append(mut records[0], mut record_count, opcode); append(mut records[0], mut record_count, 1); append(mut records[0], mut record_count, items[head + int(arg1) - 1])
				}
				7 {
					if arg1 < 1 || arg1 > i64(item_count) || arg2 < -1000000 || arg2 > 1000000 { return -1 }
					items[head + int(arg1) - 1] = arg2
					append(mut records[0], mut record_count, opcode); append(mut records[0], mut record_count, 0)
				}
				8 {
					if arg1 < -1 || arg1 > 33 || arg2 != 0 { return -1 }
					append(mut records[0], mut record_count, opcode); append(mut records[0], mut record_count, 1); append(mut records[0], mut record_count, i64(arg1 >= 1 && arg1 <= i64(item_count)))
				}
				9 {
					if arg1 != 0 || arg2 != 0 { return -1 }
					append(mut records[0], mut record_count, opcode); append(mut records[0], mut record_count, 1); append(mut records[0], mut record_count, i64(item_count))
				}
				10, 11 {
					if arg1 != 0 || arg2 != 0 { return -1 }
					append(mut records[0], mut record_count, opcode); append(mut records[0], mut record_count, i64(item_count))
					for offset in 0 .. item_count {
						logical := offset + 1
						if opcode == 11 { logical = item_count - offset }
						append(mut records[0], mut record_count, i64(logical)); append(mut records[0], mut record_count, items[head + logical - 1])
					}
				}
				else { return -1 }
			}
		}
		append(mut records[0], mut record_count, 12); append(mut records[0], mut record_count, i64(item_count))
		for offset in 0 .. item_count { append(mut records[0], mut record_count, items[head + offset]) }
		output_bytes := record_count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. record_count { write_i64_le(mut output, index * 8, records[index]) }
		return i64(output_bytes)
	}
}
