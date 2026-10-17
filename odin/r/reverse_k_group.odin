package reverse_k_group

import "core:c"

MAX_N :: 256

@(export, link_name="reverse_k_group")
reverse_k_group :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_N + 2) do return -1
	n_arg, k_arg := input[0], input[1]
	if n_arg < 0 || n_arg > MAX_N || k_arg < 1 || k_arg > MAX_N do return -1
	n, k := int(n_arg), int(k_arg)
	if length != c.size_t(n + 2) do return -1
	output_bytes := c.size_t(8 * n)
	if output == nil || capacity < output_bytes do return -2

	nodes: [MAX_N]i64
	next: [MAX_N + 1]int
	head := -1
	for i := 0; i < n; i += 1 {
		nodes[i] = input[i + 2]
		next[i] = -1
		if head < 0 do head = i
		else {
			tail := head
			for next[tail] >= 0 { tail = next[tail] }
			next[tail] = i
		}
	}
	remaining := 0
	for node := head; node >= 0; node = next[node] { remaining += 1 }
	dummy := MAX_N
	next[dummy] = head
	previous := dummy
	for remaining >= k {
		current := next[previous]
		moved := next[current]
		for step := 1; step < k; step += 1 {
			next[current] = next[moved]
			next[moved] = next[previous]
			next[previous] = moved
			moved = next[current]
		}
		previous = current
		remaining -= k
	}

	result: [MAX_N]i64
	index := 0
	for node := next[dummy]; node >= 0; node = next[node] { result[index] = nodes[node]; index += 1 }
	for i := 0; i < n; i += 1 {
		bits := transmute(u64)(result[i])
		for byte := 0; byte < 8; byte += 1 { output[i*8+byte] = u8((bits >> (8*byte)) & 255) }
	}
	return i64(output_bytes)
}
