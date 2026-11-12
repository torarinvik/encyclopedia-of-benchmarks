package virtual_tree

import "core:c"

MAX_N :: 32
MAX_K :: 32
MAX_INPUT :: 66
MAX_VIRTUAL :: 32
MAX_CANDIDATES :: 64
MAX_WORDS :: 1 + 3 * MAX_VIRTUAL

put_word :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(byte * 8)) }
}

lca :: proc "contextless" (a0, b0: int, parent: [MAX_N]int, depth: [MAX_N]int) -> int {
	a, b := a0, b0
	for depth[a] > depth[b] { a = parent[a] }
	for depth[b] > depth[a] { b = parent[b] }
	for a != b { a = parent[a]; b = parent[b] }
	return a
}

is_ancestor :: proc "contextless" (a, b: int, tin: [MAX_N]int, tout: [MAX_N]int) -> bool {
	return tin[a] <= tin[b] && tin[b] < tout[a]
}

put_sorted :: proc "contextless" (items: [^]int, count: int, tin: [MAX_N]int) {
	for i := 1; i < count; i += 1 {
		value := items[i]
		j := i
		for j > 0 && tin[items[j - 1]] > tin[value] { items[j] = items[j - 1]; j -= 1 }
		items[j] = value
	}
}

@(export)
virtual_tree :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv, kv := input[0], input[1]
	if nv < 1 || nv > MAX_N || kv < 0 || kv > MAX_K || kv > nv do return -1
	n, k := int(nv), int(kv)
	if int(length) != n + k + 1 do return -1

	var parent, depth: [MAX_N]int
	var children: [MAX_N][MAX_N]int
	var child_count: [MAX_N]int
	for vertex := 1; vertex < n; vertex += 1 {
		p_value := input[vertex + 1]
		if p_value < 0 || p_value >= i64(n) || p_value == i64(vertex) do return -1
		p := int(p_value)
		parent[vertex] = p
		children[p][child_count[p]] = vertex
		child_count[p] += 1
	}
	var marks: [MAX_K]int
	for index := 0; index < k; index += 1 {
		mark_value := input[n + 1 + index]
		if mark_value < 0 || mark_value >= i64(n) do return -1
		marks[index] = int(mark_value)
		for previous := 0; previous < index; previous += 1 {
			if marks[previous] == marks[index] do return -1
		}
	}

	var tin, tout, node_stack, next_stack: [MAX_N]int
	for vertex := 0; vertex < MAX_N; vertex += 1 { tin[vertex] = -1; tout[vertex] = -1 }
	timer, top, reached := 0, 1, 1
	node_stack[0] = 0
	tin[0] = timer
	timer += 1
	for top > 0 {
		frame := top - 1
		current := node_stack[frame]
		if next_stack[frame] == child_count[current] {
			tout[current] = timer
			top -= 1
			continue
		}
		child := children[current][next_stack[frame]]
		next_stack[frame] += 1
		if tin[child] >= 0 do return -1
		tin[child] = timer
		timer += 1
		depth[child] = depth[current] + 1
		reached += 1
		node_stack[top] = child
		next_stack[top] = 0
		top += 1
	}
	if reached != n do return -1

	var words: [MAX_WORDS]i64
	word_count := 1
	if k == 0 {
		words[0] = 0
	} else {
		put_sorted(&marks[0], k, tin)
		var nodes: [MAX_CANDIDATES]int
		var unique, stack: [MAX_VIRTUAL]int
		count := 0
		nodes[count] = 0
		count += 1
		for index := 0; index < k; index += 1 { nodes[count] = marks[index]; count += 1 }
		for index := 1; index < k; index += 1 {
			nodes[count] = lca(marks[index - 1], marks[index], parent, depth)
			count += 1
		}
		put_sorted(&nodes[0], count, tin)
		unique_count := 0
		for index := 0; index < count; index += 1 {
			if unique_count == 0 || unique[unique_count - 1] != nodes[index] {
				unique[unique_count] = nodes[index]
				unique_count += 1
			}
		}
		words[0] = i64(unique_count)
		stack_size := 0
		for index := 0; index < unique_count; index += 1 {
			vertex := unique[index]
			for stack_size > 0 && !is_ancestor(stack[stack_size - 1], vertex, tin, tout) { stack_size -= 1 }
			virtual_parent := vertex
			if stack_size > 0 { virtual_parent = stack[stack_size - 1] }
			words[word_count] = i64(vertex)
			words[word_count + 1] = i64(virtual_parent)
			words[word_count + 2] = i64(depth[vertex] - depth[virtual_parent])
			word_count += 3
			stack[stack_size] = vertex
			stack_size += 1
		}
	}
	output_bytes := word_count * 8
	if output == nil || int(capacity) < output_bytes do return -2
	for index := 0; index < word_count; index += 1 { put_word(output, index * 8, words[index]) }
	return i64(output_bytes)
}
