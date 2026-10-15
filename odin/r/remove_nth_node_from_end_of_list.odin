package remove_nth_node_from_end_of_list

import "core:c"

MAX_LIST_LENGTH :: 1024
NONE :: c.size_t(MAX_LIST_LENGTH)

// Remove a node by one-based distance from the tail in an index-based list.
@(export)
remove_nth_node_from_end_of_list :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LIST_LENGTH + 1) do return -1
	list_length := length - 1
	for index := c.size_t(0); index < list_length; index += 1 {
		if input[index + 1] < -2147483648 || input[index + 1] > 2147483647 do return -1
	}
	if input[0] < 1 || u64(input[0]) > u64(list_length) do return -1

	next_node: [MAX_LIST_LENGTH]c.size_t
	for index := c.size_t(0); index < list_length; index += 1 {
		if index + 1 < list_length do next_node[index] = index + 1
		else do next_node[index] = NONE
	}
	node := c.size_t(0)
	counted := c.size_t(0)
	for node != NONE {
		node = next_node[node]
		counted += 1
	}
	if counted != list_length do return -1

	steps_to_target := counted - c.size_t(input[0])
	before := NONE
	node = 0
	for step := c.size_t(0); step < steps_to_target; step += 1 {
		before = node
		node = next_node[node]
	}
	head := c.size_t(0)
	if before == NONE do head = next_node[node]
	else do next_node[before] = next_node[node]

	output_count := counted - 1
	output_bytes := output_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	node = head
	written := c.size_t(0)
	for node != NONE {
		bits := u32(i32(input[node + 1]))
		for byte := c.size_t(0); byte < 4; byte += 1 {
			output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
		}
		node = next_node[node]
		written += 1
	}
	if written != output_count do return -1
	return i64(written)
}
