package depth_first_search_iterative_order

import "core:c"

MAX_VERTICES :: 10
MAX_DEGREE :: 128

put_i64_le :: proc "contextless" (output: [^]u8, word: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 {
		output[word * 8 + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
depth_first_search_iterative_order :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	n_value, edge_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_VERTICES || edge_value < 0 || edge_value > 64 do return -1
	n := int(n_value)
	edge_count := int(edge_value)
	if length != c.size_t(3 + 2 * edge_count) do return -1
	adjacency: [MAX_VERTICES + 1][MAX_DEGREE]int
	degree: [MAX_VERTICES + 1]int
	position: c.size_t = 2
	for _ in 0 .. edge_count {
		left_value, right_value := input[position], input[position + 1]
		position += 2
		if left_value < 1 || left_value > n_value || right_value < 1 || right_value > n_value do return -1
		left, right := int(left_value), int(right_value)
		adjacency[left][degree[left]] = right
		degree[left] += 1
		adjacency[right][degree[right]] = left
		degree[right] += 1
	}
	start_value := input[position]
	if start_value < 1 || start_value > n_value do return -1
	start := int(start_value)
	stack: [MAX_VERTICES]int
	order: [MAX_VERTICES]int
	visited: [MAX_VERTICES + 1]bool
	visited[start] = true
	stack_size, order_count := 1, 0
	stack[0] = start
	for stack_size > 0 {
		stack_size -= 1
		vertex := stack[stack_size]
		order[order_count] = vertex
		order_count += 1
		for edge := 0; edge < degree[vertex]; edge += 1 {
			neighbor := adjacency[vertex][edge]
			if !visited[neighbor] {
				visited[neighbor] = true
				stack[stack_size] = neighbor
				stack_size += 1
			}
		}
	}
	words := c.size_t(order_count + 1)
	if output == nil || capacity < words * 8 do return -2
	put_i64_le(output, 0, i64(order_count))
	for index := 0; index < order_count; index += 1 {
		put_i64_le(output, c.size_t(index + 1), i64(order[index]))
	}
	return i64(words * 8)
}
