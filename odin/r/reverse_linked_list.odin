package reverse_linked_list

import "core:c"

MAX_N :: 256

@(export, link_name="reverse_linked_list")
reverse_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_N + 1) do return -1
	n_arg := input[0]
	if n_arg < 1 || n_arg > MAX_N do return -1
	n := int(n_arg)
	if length != c.size_t(n + 1) do return -1
	output_bytes := c.size_t(8 * n)
	if output == nil || capacity < output_bytes do return -2

	nodes: [MAX_N]i64
	next: [MAX_N]int
	previous_link: [MAX_N]int
	for i := 0; i < n; i += 1 {
		nodes[i] = input[i + 1]
		next[i] = if i + 1 < n do i + 1 else -1
		previous_link[i] = if i > 0 do i - 1 else -1
	}
	previous := -1
	current := 0
	for current >= 0 {
		next_node := next[current]
		next[current] = previous
		previous_link[current] = next_node
		previous = current
		current = next_node
	}
	node := previous
	expected_previous := -1
	result: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		if node < 0 || previous_link[node] != expected_previous do return -1
		result[i] = nodes[node]
		expected_previous = node
		node = next[node]
	}
	if node >= 0 do return -1
	for i := 0; i < n; i += 1 {
		bits := transmute(u64)(result[i])
		for byte := 0; byte < 8; byte += 1 { output[i*8+byte] = u8((bits >> (8*byte)) & 255) }
	}
	return i64(output_bytes)
}
