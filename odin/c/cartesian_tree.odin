package cartesian_tree

import "core:c"

MAX_N :: 128

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
cartesian_tree :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 1 + MAX_N do return -1
	n_value := input[0]
	if n_value < 1 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if length != c.size_t(n + 1) do return -1

	parent: [MAX_N]i64
	stack: [MAX_N]int
	for i := 0; i < n; i += 1 {
		key := input[i + 1]
		if key < 0 || key > 1_000_000_000 do return -1
		parent[i] = i64(i)
	}

	stack_size := 0
	for i := 0; i < n; i += 1 {
		last := MAX_N
		for stack_size > 0 && input[stack[stack_size - 1] + 1] > input[i + 1] {
			stack_size -= 1
			last = stack[stack_size]
		}
		if stack_size > 0 do parent[i] = i64(stack[stack_size - 1])
		if last < MAX_N do parent[last] = i64(i)
		stack[stack_size] = i
		stack_size += 1
	}

	output_bytes := n * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < n; i += 1 {
		store_i64_le(output, i * 8, parent[i])
	}
	return i64(output_bytes)
}
