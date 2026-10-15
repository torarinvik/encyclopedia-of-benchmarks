package delete_middle_node

import "core:c"

MAX_NODES :: 1024
MAX_LINKS :: 1025

// Delete the floor(n / 2)-indexed node using the source's fast/slow traversal.
@(export)
delete_middle_node :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_NODES || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < -2147483648 || input[index] > 2147483647 do return -1
	}
	if length <= 1 do return 0
	next_node: [MAX_LINKS]c.size_t = {}
	for index := c.size_t(0); index < length; index += 1 { next_node[index] = index + 1 }
	next_node[length] = length
	node_count := c.size_t(0)
	for cursor := c.size_t(0); cursor != length; cursor = next_node[cursor] { node_count += 1 }
	fast := c.size_t(0)
	slow := c.size_t(0)
	previous := length
	for next_node[fast] != length && next_node[next_node[fast]] != length {
		previous = slow
		slow = next_node[slow]
		fast = next_node[next_node[fast]]
	}
	if node_count % 2 == 0 { previous = slow; slow = next_node[slow] }
	next_node[previous] = next_node[slow]
	survivor_count := node_count - 1
	output_bytes := survivor_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	written := c.size_t(0)
	for node := c.size_t(0); node != length; node = next_node[node] {
		bits := u32(i32(input[node]))
		for byte := c.size_t(0); byte < 4; byte += 1 {
			output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
		}
		written += 1
	}
	return i64(written)
}
