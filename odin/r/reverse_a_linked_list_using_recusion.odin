package reverse_a_linked_list_using_recusion

import "core:c"

MAX_N :: 64
I32_MIN :: -2147483648
I32_MAX :: 2147483647

reverse_links :: proc(next: ^[MAX_N]int, previous, current: int) -> int {
	if next[current] >= 0 {
		head := reverse_links(next, current, next[current])
		next[current] = previous
		next[previous] = -1
		return head
	}
	next[current] = previous
	next[previous] = -1
	return current
}

@(export, link_name="reverse_a_linked_list_using_recusion")
reverse_a_linked_list_using_recusion :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_N + 1) do return -1
	if input[0] < 2 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	for i := 0; i < n; i += 1 {
		if input[i + 1] < I32_MIN || input[i + 1] > I32_MAX do return -1
	}
	bytes := c.size_t(4 * n)
	if output == nil || capacity < bytes do return -2

	nodes: [MAX_N]i32
	next: [MAX_N]int
	for i := 0; i < n; i += 1 {
		nodes[i] = i32(input[i + 1])
		next[i] = -1
		if i + 1 < n do next[i] = i + 1
	}
	node := reverse_links(&next, 0, next[0])
	for i := 0; i < n; i += 1 {
		bits := transmute(u32)(nodes[node])
		for byte := 0; byte < 4; byte += 1 {
			output[i*4+byte] = u8((bits >> (8*byte)) & 255)
		}
		if i + 1 < n do node = next[node]
	}
	return i64(bytes)
}
