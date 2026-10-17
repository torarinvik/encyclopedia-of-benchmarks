package linkedlist_implentation_usingarray

import "core:c"

MAX_INPUT_LENGTH :: 202
MAX_LIST_LENGTH :: 100

write_i32_le :: proc(output: [^]u8, index: int, value: i32) {
	bits := transmute(u32)value
	offset := index * 4
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
linkedlist_implentation_usingarray :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	operation_count := input[0]
	if operation_count < 0 || operation_count > 100 || int(length) != 1+2*int(operation_count) do return -1
	items: [MAX_LIST_LENGTH]i32
	item_count, cursor := 0, 1
	for _ in 0..<int(operation_count) {
		opcode, raw_value := input[cursor], input[cursor+1]
		cursor += 2
		if raw_value < -2_147_483_648 || raw_value > 2_147_483_647 || item_count >= MAX_LIST_LENGTH do return -1
		value := i32(raw_value)
		if opcode == 0 {
			for index := item_count; index > 0; index -= 1 { items[index] = items[index-1] }
			items[0] = value
			item_count += 1
		} else if opcode == 1 {
			if item_count == 0 do return -1
			items[item_count] = value
			item_count += 1
		} else {
			return -1
		}
	}
	output_bytes := (item_count+1)*4
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	write_i32_le(output, 0, i32(item_count))
	for index in 0..<item_count { write_i32_le(output, index+1, items[index]) }
	return i64(output_bytes)
}
