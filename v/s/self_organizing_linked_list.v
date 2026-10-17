module self_organizing_linked_list

const max_input_length = 130
const max_operations = 64
const max_list_length = 64
const max_output_fields = 194

fn append_i64(mut records &i64, mut count &int, value i64) {
	unsafe { records[count] = value }
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

@[export: 'self_organizing_linked_list']
pub fn self_organizing_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		operation_count := input[0]
		if operation_count < 0 || operation_count > max_operations || int(length) != 1 + 2 * int(operation_count) { return -1 }
		mut items := [max_list_length]i64{}
		mut records := [max_output_fields]i64{}
		mut item_count := 0
		mut record_count := 0
		mut cursor := 1
		for _ in 0 .. int(operation_count) {
			opcode, value := input[cursor], input[cursor + 1]
			cursor += 2
			if value < -2147483648 || value > 2147483647 { return -1 }
			if opcode == 0 {
				if item_count == max_list_length { return -1 }
				items[item_count] = value
				item_count++
				append_i64(mut records[0], mut record_count, 0)
				append_i64(mut records[0], mut record_count, 0)
			} else if opcode == 1 {
				mut found_at := 0
				for found_at < item_count && items[found_at] != value { found_at++ }
				found := if found_at < item_count { i64(1) } else { i64(0) }
				append_i64(mut records[0], mut record_count, 1)
				append_i64(mut records[0], mut record_count, 1)
				append_i64(mut records[0], mut record_count, found)
				if found != 0 && found_at != 0 {
					for index := found_at; index > 0; index-- { items[index] = items[index - 1] }
					items[0] = value
				}
			} else {
				return -1
			}
		}
		append_i64(mut records[0], mut record_count, 2)
		append_i64(mut records[0], mut record_count, i64(item_count))
		for index in 0 .. item_count { append_i64(mut records[0], mut record_count, items[index]) }
		output_bytes := record_count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. record_count { write_i64_le(mut output, index * 8, records[index]) }
		return i64(output_bytes)
	}
}
