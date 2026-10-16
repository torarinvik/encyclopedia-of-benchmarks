package stalin_sort

import "core:c"

MAX_INPUT_LENGTH :: 128

store_i32_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

// Keep each value that is not smaller than the last retained value.
@(export)
stalin_sort :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_INPUT_LENGTH || (length != 0 && values == nil) do return -1
	for index := 0; index < int(length); index += 1 {
		if values[index] < -2147483648 || values[index] > 2147483647 do return -1
	}
	kept := 0
	last := i64(0)
	for index := 0; index < int(length); index += 1 {
		if kept == 0 || values[index] >= last {
			kept += 1
			last = values[index]
		}
	}
	output_bytes := kept * 4
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	output_index := 0
	last = 0
	for index := 0; index < int(length); index += 1 {
		if output_index == 0 || values[index] >= last {
			store_i32_le(output, output_index * 4, values[index])
			output_index += 1
			last = values[index]
		}
	}
	return i64(output_bytes)
}
