package burrows_wheeler_transform

import "core:c"

rotation_less :: proc(values: [^]i64, n, left, right: int) -> bool {
	for offset := 0; offset < n; offset += 1 {
		a := values[1 + (left + offset) % n]
		b := values[1 + (right + offset) % n]
		if a != b do return a < b
	}
	return left < right
}

@(export)
burrows_wheeler_transform :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || values[0] < 1 || values[0] > 256 do return -1
	n := int(values[0])
	if length != c.size_t(n + 1) do return -1
	for i := 1; i < int(length); i += 1 { if values[i] < 0 || values[i] > 127 do return -1 }
	output_length := n + 4
	if output_capacity < c.size_t(output_length) || output == nil do return -2

	order: [256]usize
	for i := 0; i < n; i += 1 { order[i] = usize(i) }
	for i := 1; i < n; i += 1 {
		key := order[i]
		position := i
		for position > 0 && rotation_less(values, n, int(key), int(order[position - 1])) {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = key
	}

	primary_index := 0
	for row := 0; row < n; row += 1 { if order[row] == 0 do primary_index = row }
	encoded_index := u32(primary_index)
	for byte := 0; byte < 4; byte += 1 { output[byte] = u8((encoded_index >> u32(8 * byte)) & 0xff) }
	for row := 0; row < n; row += 1 {
		start := int(order[row])
		output[4 + row] = u8(values[1 + (start + n - 1) % n])
	}
	return i64(output_length)
}
