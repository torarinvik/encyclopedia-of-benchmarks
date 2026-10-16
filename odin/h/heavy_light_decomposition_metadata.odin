package heavy_light_decomposition_metadata

import "core:c"

MAX_VERTICES :: 128

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
heavy_light_decomposition_metadata :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	nv, mv := input[0], input[1]
	if nv < 1 || nv > MAX_VERTICES || mv != nv - 1 || length != c.size_t(2 + 2 * mv) do return -1
	n, m := int(nv), int(mv)
	var adjacency: [MAX_VERTICES * MAX_VERTICES]int
	var degree: [MAX_VERTICES]int
	for edge := 0; edge < m; edge += 1 {
		uv, vv := input[2 + 2 * edge], input[3 + 2 * edge]
		if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv do return -1
		u, v := int(uv), int(vv)
		for i := 0; i < degree[u]; i += 1 {
			if adjacency[u * MAX_VERTICES + i] == v do return -1
		}
		adjacency[u * MAX_VERTICES + degree[u]] = v
		degree[u] += 1
		adjacency[v * MAX_VERTICES + degree[v]] = u
		degree[v] += 1
	}
	var parent: [MAX_VERTICES]int
	var order: [MAX_VERTICES]int
	var stack: [MAX_VERTICES]int
	for v := 0; v < n; v += 1 do parent[v] = -2
	parent[0] = -1
	top, order_count := 1, 0
	stack[0] = 0
	for top > 0 {
		top -= 1
		vertex := stack[top]
		order[order_count] = vertex
		order_count += 1
		for i := degree[vertex] - 1; i >= 0; i -= 1 {
			child := adjacency[vertex * MAX_VERTICES + i]
			if parent[child] == -2 {
				parent[child] = vertex
				stack[top] = child
				top += 1
			}
		}
	}
	if order_count != n do return -1
	var subtree_size: [MAX_VERTICES]int
	var big_child: [MAX_VERTICES]int
	for index := n - 1; index >= 0; index -= 1 {
		vertex := order[index]
		best_size := 0
		subtree_size[vertex] = 1
		big_child[vertex] = -1
		for i := 0; i < degree[vertex]; i += 1 {
			child := adjacency[vertex * MAX_VERTICES + i]
			if parent[child] != vertex do continue
			subtree_size[vertex] += subtree_size[child]
			if subtree_size[child] > best_size {
				best_size = subtree_size[child]
				big_child[vertex] = child
			}
		}
	}
	var position: [MAX_VERTICES]int
	var head: [MAX_VERTICES]int
	var stack_head: [MAX_VERTICES]int
	top = 1
	next_position := 0
	stack[0] = 0
	stack_head[0] = 0
	for top > 0 {
		top -= 1
		vertex, chain_head := stack[top], stack_head[top]
		position[vertex] = next_position
		next_position += 1
		head[vertex] = chain_head
		for i := degree[vertex] - 1; i >= 0; i -= 1 {
			child := adjacency[vertex * MAX_VERTICES + i]
			if parent[child] == vertex && child != big_child[vertex] {
				stack[top] = child
				stack_head[top] = child
				top += 1
			}
		}
		if big_child[vertex] >= 0 {
			stack[top] = big_child[vertex]
			stack_head[top] = chain_head
			top += 1
		}
	}
	required := (1 + 3 * n) * 8
	if output == nil || capacity < c.size_t(required) do return -2
	cursor := 0
	put_i64(output, cursor * 8, nv)
	cursor += 1
	for vertex := 0; vertex < n; vertex += 1 {
		put_i64(output, cursor * 8, i64(position[vertex]))
		cursor += 1
		put_i64(output, cursor * 8, i64(head[vertex]))
		cursor += 1
		put_i64(output, cursor * 8, i64(big_child[vertex]))
		cursor += 1
	}
	return i64(required)
}
