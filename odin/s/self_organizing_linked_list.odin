package self_organizing_linked_list

import "core:c"

MAX_INPUT_LENGTH :: 130
MAX_OPERATIONS :: 64
MAX_LIST_LENGTH :: 64
MAX_OUTPUT_FIELDS :: 194

append_i64 :: proc(records: [^]i64, count: ^int, value: i64) {
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
self_organizing_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	operation_count := input[0]
	if operation_count < 0 || operation_count > i64(MAX_OPERATIONS) ||
		int(length) != 1 + 2*int(operation_count) do return -1
	items: [MAX_LIST_LENGTH]i64
	records: [MAX_OUTPUT_FIELDS]i64
	item_count, record_count, cursor := 0, 0, 1
	for _ in 0..<int(operation_count) {
		opcode, value := input[cursor], input[cursor+1]
		cursor += 2
		if value < -2147483648 || value > 2147483647 do return -1
		if opcode == 0 {
			if item_count == MAX_LIST_LENGTH do return -1
			items[item_count] = value
			item_count += 1
			append_i64(&records[0], &record_count, 0)
			append_i64(&records[0], &record_count, 0)
		} else if opcode == 1 {
			found_at := 0
			for found_at < item_count && items[found_at] != value { found_at += 1 }
			found: i64 = 0
			if found_at < item_count do found = 1
			append_i64(&records[0], &record_count, 1)
			append_i64(&records[0], &record_count, 1)
			append_i64(&records[0], &record_count, found)
			if found != 0 && found_at != 0 {
				for index := found_at; index > 0; index -= 1 { items[index] = items[index-1] }
				items[0] = value
			}
		} else {
			return -1
		}
	}
	append_i64(&records[0], &record_count, 2)
	append_i64(&records[0], &record_count, i64(item_count))
	for index in 0..<item_count { append_i64(&records[0], &record_count, items[index]) }
	output_bytes := record_count*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index in 0..<record_count { write_i64_le(output, index*8, records[index]) }
	return i64(output_bytes)
}
