package remove_linked_list_elements

import "core:c"

MAX_NODES :: 1024
MAX_LINKS :: 1025

remove_chain :: proc "contextless" (input: [^]i64, next_node: [^]c.size_t,
		node, none: c.size_t, target: i64) -> c.size_t {
	if node == none do return none
	next := next_node[node]
	if input[node + 1] == target do return remove_chain(input, next_node, next, none, target)
	next_node[node] = remove_chain(input, next_node, next, none, target)
	return node
}

@(export)
remove_linked_list_elements :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > MAX_NODES + 1 do return -1
	target := input[0]
	if target < -2147483648 || target > 2147483647 do return -1
	node_count := length - 1
	next_node: [MAX_LINKS]c.size_t = {}
	for index := c.size_t(0); index < node_count; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		next_node[index] = index + 1
	}
	next_node[node_count] = node_count
	head := c.size_t(0)
	if node_count == 0 do head = node_count
	head = remove_chain(input, &next_node[0], head, node_count, target)
	survivor_count := c.size_t(0)
	node := head
	for node != node_count {
		survivor_count += 1
		node = next_node[node]
	}
	output_bytes := survivor_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	written := c.size_t(0)
	node = head
	for node != node_count {
		bits := u32(i32(input[node + 1]))
		for byte := c.size_t(0); byte < 4; byte += 1 {
			output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
		}
		written += 1
		node = next_node[node]
	}
	return i64(written)
}
