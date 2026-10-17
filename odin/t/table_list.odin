package table_list

import "core:c"

MAX_INPUT_LENGTH :: 98
MAX_OUTPUT_FIELDS :: 594
MIN_VALUE :: i64(-1_000_000)
MAX_VALUE :: i64(1_000_000)

append :: proc(records: [^]i64, count: ^int, value: i64) {
	records[count^] = value
	count^ += 1
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
table_list :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	operation_count := input[0]
	if operation_count < 0 || operation_count > 32 || int(length) != 1+3*int(operation_count) do return -1
	items: [64]i64
	records: [MAX_OUTPUT_FIELDS]i64
	head, item_count, record_count, cursor := 32, 0, 0, 1
	for _ in 0..<int(operation_count) {
		opcode, arg1, arg2 := input[cursor], input[cursor+1], input[cursor+2]
		cursor += 3
		switch opcode {
		case 0:
			if arg1 < MIN_VALUE || arg1 > MAX_VALUE || arg2 != 0 || item_count >= 32 do return -1
			head -= 1
			items[head] = arg1
			item_count += 1
			append(&records[0], &record_count, opcode); append(&records[0], &record_count, 0)
		case 1:
			if arg1 < MIN_VALUE || arg1 > MAX_VALUE || arg2 != 0 || item_count >= 32 do return -1
			items[head+item_count] = arg1
			item_count += 1
			append(&records[0], &record_count, opcode); append(&records[0], &record_count, 0)
		case 2:
			if arg1 != 0 || arg2 != 0 do return -1
			append(&records[0], &record_count, opcode)
			if item_count == 0 { append(&records[0], &record_count, 0) }
			else {
				append(&records[0], &record_count, 1); append(&records[0], &record_count, items[head])
				head += 1; item_count -= 1
			}
		case 3:
			if arg1 != 0 || arg2 != 0 do return -1
			append(&records[0], &record_count, opcode)
			if item_count == 0 { append(&records[0], &record_count, 0) }
			else {
				append(&records[0], &record_count, 1); item_count -= 1
				append(&records[0], &record_count, items[head+item_count])
			}
		case 4, 5:
			if arg1 != 0 || arg2 != 0 do return -1
			append(&records[0], &record_count, opcode)
			if item_count == 0 { append(&records[0], &record_count, 0) }
			else {
				append(&records[0], &record_count, 1)
				append(&records[0], &record_count, if opcode == 4 { items[head] } else { items[head+item_count-1] })
			}
		case 6:
			if arg2 != 0 || arg1 < 1 || arg1 > i64(item_count) do return -1
			append(&records[0], &record_count, opcode); append(&records[0], &record_count, 1)
			append(&records[0], &record_count, items[head+int(arg1)-1])
		case 7:
			if arg1 < 1 || arg1 > i64(item_count) || arg2 < MIN_VALUE || arg2 > MAX_VALUE do return -1
			items[head+int(arg1)-1] = arg2
			append(&records[0], &record_count, opcode); append(&records[0], &record_count, 0)
		case 8:
			if arg1 < -1 || arg1 > 33 || arg2 != 0 do return -1
			append(&records[0], &record_count, opcode); append(&records[0], &record_count, 1)
			append(&records[0], &record_count, if arg1 >= 1 && arg1 <= i64(item_count) { 1 } else { 0 })
		case 9:
			if arg1 != 0 || arg2 != 0 do return -1
			append(&records[0], &record_count, opcode); append(&records[0], &record_count, 1); append(&records[0], &record_count, i64(item_count))
		case 10, 11:
			if arg1 != 0 || arg2 != 0 do return -1
			append(&records[0], &record_count, opcode); append(&records[0], &record_count, i64(item_count))
			for offset in 0..<item_count {
				logical := offset+1
				if opcode == 11 do logical = item_count-offset
				append(&records[0], &record_count, i64(logical)); append(&records[0], &record_count, items[head+logical-1])
			}
		case:
			return -1
		}
	}
	append(&records[0], &record_count, 12); append(&records[0], &record_count, i64(item_count))
	for offset in 0..<item_count { append(&records[0], &record_count, items[head+offset]) }
	output_bytes := record_count*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index in 0..<record_count { write_i64_le(output, index*8, records[index]) }
	return i64(output_bytes)
}
