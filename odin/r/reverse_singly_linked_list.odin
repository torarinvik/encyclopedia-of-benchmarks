package reverse_singly_linked_list

import "core:c"

MAX_LENGTH :: 256

write_i32_le :: proc(output: [^]u8, index: int, value: i32) {
	bits := transmute(u32)value
	offset := index * 4
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
reverse_singly_linked_list :: proc "c" (values: [^]i32, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length > c.size_t(MAX_LENGTH) do return -1
	output_bytes := int(length) * 4
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < int(length); index += 1 {
		write_i32_le(output, index, values[int(length)-1-index])
	}
	return i64(output_bytes)
}
