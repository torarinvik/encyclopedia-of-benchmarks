package remove_all_duplicates_from_sorted_list

import "core:c"

MAX_NODES :: 1024
MAX_LINKS :: 1025

remove_duplicate_runs :: proc "contextless" (input: [^]i64, next_node: [^]c.size_t,
		node, none: c.size_t) -> c.size_t {
	if node == none do return none
	next := next_node[node]
	if next != none && input[node] == input[next] {
		duplicate := input[node]
		after_run := next
		for after_run != none && input[after_run] == duplicate {
			after_run = next_node[after_run]
		}
		return remove_duplicate_runs(input, next_node, after_run, none)
	}
	next_node[node] = remove_duplicate_runs(input, next_node, next, none)
	return node
}

@(export)
remove_all_duplicates_from_sorted_list :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_NODES || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		value := input[index]
		if value < -2147483648 || value > 2147483647 || (index > 0 && input[index - 1] > value) do return -1
	}
	next_node: [MAX_LINKS]c.size_t = {}
	for index := c.size_t(0); index < length; index += 1 { next_node[index] = index + 1 }
	next_node[length] = length
	head := remove_duplicate_runs(input, &next_node[0], c.size_t(0), length)
	survivor_count := c.size_t(0)
	for node := head; node != length; node = next_node[node] { survivor_count += 1 }
	output_bytes := survivor_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	written := c.size_t(0)
	for node := head; node != length; node = next_node[node] {
		bits := u32(i32(input[node]))
		for byte := c.size_t(0); byte < 4; byte += 1 {
			output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
		}
		written += 1
	}
	if written != survivor_count do return -1
	return i64(written)
}
