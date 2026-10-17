package reverse_kgroup

import "core:c"

MAX_INPUT_LENGTH :: 258
MAX_LIST_LENGTH :: 256

write_i32_le :: proc(output: [^]u8, index: int, value: i32) {
	bits := transmute(u32)value
	offset := index * 4
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
reverse_kgroup :: proc "c" (input: [^]i32, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	group_size_value := input[0]
	list_length := int(length) - 1
	if group_size_value < 1 || group_size_value > i32(MAX_LIST_LENGTH) || list_length > MAX_LIST_LENGTH do return -1
	group_size := int(group_size_value)
	output_bytes := list_length * 4
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	start := 0
	for start+group_size <= list_length {
		for offset := 0; offset < group_size; offset += 1 {
			write_i32_le(output, start+offset, input[1+start+group_size-1-offset])
		}
		start += group_size
	}
	for start < list_length {
		write_i32_le(output, start, input[1+start])
		start += 1
	}
	return i64(output_bytes)
}
