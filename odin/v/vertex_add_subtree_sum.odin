package vertex_add_subtree_sum

import "core:c"

MAX_N :: 128
MAX_Q :: 256
MAX_INPUT_VALUES :: 2 * MAX_N + 1 + 3 * MAX_Q
MAX_VALUE :: i64(1_000_000)

fenwick_add :: proc "contextless" (tree: [^]i64, n, position: int, delta: i64) {
	index := position + 1
	for index <= n {
		tree[index] += delta
		index += index & -index
	}
}

fenwick_prefix :: proc "contextless" (tree: [^]i64, count: int) -> i64 {
	mut total: i64 = 0
	mut index := count
	for index > 0 {
		total += tree[index]
		index -= index & -index
	}
	return total
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (byte * 8)) }
}

@(export)
vertex_add_subtree_sum :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
	n, q := int(nv), int(qv)
	if length != c.size_t(2 * n + 1 + 3 * q) do return -1

	var values: [MAX_N]i64
	var first_child, next_sibling: [MAX_N]i64
	for vertex := 0; vertex < MAX_N; vertex += 1 {
		first_child[vertex], next_sibling[vertex] = -1, -1
	}
	for vertex := 0; vertex < n; vertex += 1 {
		values[vertex] = input[2 + vertex]
		if values[vertex] < 0 || values[vertex] > MAX_VALUE do return -1
	}
	parent_start := 2 + n
	for vertex := 1; vertex < n; vertex += 1 {
		parent_value := input[parent_start + vertex - 1]
		if parent_value < 0 || parent_value >= i64(vertex) do return -1
		parent := int(parent_value)
		next_sibling[vertex] = first_child[parent]
		first_child[parent] = i64(vertex)
	}

	var tin, tout, stack_node: [MAX_N]int
	var stack_next_child: [MAX_N]i64
	timer, top := 0, 1
	stack_node[0], stack_next_child[0] = 0, first_child[0]
	tin[0] = timer
	timer += 1
	for top > 0 {
		frame := top - 1
		child_value := stack_next_child[frame]
		if child_value < 0 {
			tout[stack_node[frame]] = timer
			top -= 1
			continue
		}
		child := int(child_value)
		stack_next_child[frame] = next_sibling[child]
		tin[child] = timer
		timer += 1
		stack_node[top], stack_next_child[top] = child, first_child[child]
		top += 1
	}

	var fenwick: [MAX_N + 1]i64
	for vertex := 0; vertex < n; vertex += 1 {
		fenwick_add(&fenwick[0], n, tin[vertex], values[vertex])
	}
	var answers: [MAX_Q]i64
	answer_count := 0
	operation_start := parent_start + n - 1
	for operation_index := 0; operation_index < q; operation_index += 1 {
		offset := operation_start + 3 * operation_index
		kind, vertex_value, operand := input[offset], input[offset + 1], input[offset + 2]
		if kind == 0 {
			if vertex_value < 0 || vertex_value >= nv || operand < 0 || operand > MAX_VALUE do return -1
			vertex := int(vertex_value)
			values[vertex] += operand
			fenwick_add(&fenwick[0], n, tin[vertex], operand)
		} else if kind == 1 {
			if vertex_value < 0 || vertex_value >= nv || operand != 0 do return -1
			vertex := int(vertex_value)
			answers[answer_count] = fenwick_prefix(&fenwick[0], tout[vertex]) -
				fenwick_prefix(&fenwick[0], tin[vertex])
			answer_count += 1
		} else do return -1
	}

	output_bytes := 8 * answer_count
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2
	for index := 0; index < answer_count; index += 1 {
		store_i64_le(output, 8 * index, answers[index])
	}
	return i64(output_bytes)
}
