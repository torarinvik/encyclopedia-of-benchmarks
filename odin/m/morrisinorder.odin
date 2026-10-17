package morrisinorder

import "core:c"

MAX_NODE_COUNT :: 63
MAX_PARSEABLE_INPUT_LENGTH :: 65

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> u32(byte * 8))
	}
}

@(export)
morrisinorder :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	raw_count := values[0]
	if raw_count < 0 || raw_count > MAX_NODE_COUNT do return -1
	count := int(raw_count)
	if length != c.size_t(count + 1) do return -1
	for index := 0; index < count; index += 1 {
		node := values[index + 1]
		if node < -2147483648 || node > 2147483647 do return -1
	}

	byte_count := count * 4
	if output == nil || output_capacity < c.size_t(byte_count) do return -2

	left_nodes: [MAX_NODE_COUNT]int
	right_nodes: [MAX_NODE_COUNT]int
	for index := 0; index < count; index += 1 {
		left_index := 2 * index + 1
		right_index := 2 * index + 2
		left_nodes[index] = if left_index < count { left_index } else { -1 }
		right_nodes[index] = if right_index < count { right_index } else { -1 }
	}

	current := -1
	if count > 0 do current = 0
	written := 0
	for current >= 0 {
		if left_nodes[current] < 0 {
			store_i32_le(output, written * 4, i32(values[current + 1]))
			written += 1
			current = right_nodes[current]
		} else {
			predecessor := left_nodes[current]
			for right_nodes[predecessor] >= 0 && right_nodes[predecessor] != current {
				predecessor = right_nodes[predecessor]
			}
			if right_nodes[predecessor] < 0 {
				right_nodes[predecessor] = current
				current = left_nodes[current]
			} else {
				right_nodes[predecessor] = -1
				store_i32_le(output, written * 4, i32(values[current + 1]))
				written += 1
				current = right_nodes[current]
			}
		}
	}
	return i64(byte_count)
}
