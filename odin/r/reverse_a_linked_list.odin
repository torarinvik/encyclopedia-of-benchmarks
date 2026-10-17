package reverse_a_linked_list

import "core:c"

MAX_N :: 128
I32_MIN :: -2147483648
I32_MAX :: 2147483647

@(export, link_name="reverse_a_linked_list")
reverse_a_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_N + 1) do return -1
	n_arg := input[0]
	if n_arg < 0 || n_arg > MAX_N do return -1
	n := int(n_arg)
	if length != c.size_t(n + 1) do return -1
	for i := 0; i < n; i += 1 { if input[i + 1] < I32_MIN || input[i + 1] > I32_MAX do return -1 }
	output_bytes := c.size_t(4 * n)
	if output == nil || capacity < output_bytes do return -2

	nodes: [MAX_N]i32
	next: [MAX_N]int
	head := -1
	for i := 0; i < n; i += 1 {
		nodes[i] = i32(input[i + 1])
		next[i] = -1
		if head < 0 do head = i
		else {
			tail := head
			for next[tail] >= 0 { tail = next[tail] }
			next[tail] = i
		}
	}
	previous := -1
	current := head
	for current >= 0 {
		next_node := next[current]
		next[current] = previous
		previous = current
		current = next_node
	}
	head = previous
	for index := 0; index < n; index += 1 {
		node := head
		for step := 0; step < index; step += 1 { node = next[node] }
		bits := transmute(u32)(nodes[node])
		for byte := 0; byte < 4; byte += 1 { output[index*4+byte] = u8((bits >> (8*byte)) & 255) }
	}
	return i64(output_bytes)
}
