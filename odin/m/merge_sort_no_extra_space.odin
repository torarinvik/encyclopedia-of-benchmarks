package merge_sort_no_extra_space

import "core:c"

MAX_LENGTH :: 256

read_i32_le :: proc(buffer: [^]u8, index: int) -> i32 {
	offset := index * 4
	bits := u32(buffer[offset]) | (u32(buffer[offset+1]) << 8) | (u32(buffer[offset+2]) << 16) | (u32(buffer[offset+3]) << 24)
	return transmute(i32)bits
}

write_i32_le :: proc(buffer: [^]u8, index: int, value: i32) {
	bits := transmute(u32)value
	offset := index * 4
	for byte := 0; byte < 4; byte += 1 {
		buffer[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

merge :: proc(buffer: [^]u8, start, middle, finish: int, max_element: i32) {
	i, j, k := start, middle+1, start
	for i <= middle && j <= finish {
		left := read_i32_le(buffer, i) % max_element
		right := read_i32_le(buffer, j) % max_element
		current := read_i32_le(buffer, k)
		if left <= right {
			write_i32_le(buffer, k, current+left*max_element)
			i += 1
		} else {
			write_i32_le(buffer, k, current+right*max_element)
			j += 1
		}
		k += 1
	}
	for i <= middle {
		current := read_i32_le(buffer, k)
		next := read_i32_le(buffer, i) % max_element
		write_i32_le(buffer, k, current+next*max_element)
		i += 1
		k += 1
	}
	for j <= finish {
		current := read_i32_le(buffer, k)
		next := read_i32_le(buffer, j) % max_element
		write_i32_le(buffer, k, current+next*max_element)
		j += 1
		k += 1
	}
	for index := start; index <= finish; index += 1 {
		write_i32_le(buffer, index, read_i32_le(buffer, index)/max_element)
	}
}

merge_sort :: proc(buffer: [^]u8, start, finish: int, max_element: i32) {
	if start >= finish do return
	middle := start + (finish-start)/2
	merge_sort(buffer, start, middle, max_element)
	merge_sort(buffer, middle+1, finish, max_element)
	merge(buffer, start, middle, finish, max_element)
}

@(export)
merge_sort_no_extra_space :: proc "c" (values: [^]i32, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length > c.size_t(MAX_LENGTH) do return -1
	max_value: i32 = 0
	for index := 0; index < int(length); index += 1 {
		if values[index] < 0 || values[index] > 32767 do return -1
		max_value = max(max_value, values[index])
	}
	output_bytes := int(length)*4
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < int(length); index += 1 { write_i32_le(output, index, values[index]) }
	if length > 1 do merge_sort(output, 0, int(length)-1, max_value+1)
	return i64(output_bytes)
}
