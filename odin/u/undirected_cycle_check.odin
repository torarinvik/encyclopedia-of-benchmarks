package undirected_cycle_check

import "core:c"

MAX_VERTICES :: 32
MAX_EDGES :: 256
MAX_MATRIX :: MAX_VERTICES * MAX_VERTICES

// Detect cycles in a bounded simple undirected graph with iterative DFS.
@(export)
undirected_cycle_check :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	vertices := int(input[0])
	edges := int(input[1])
	if length != c.size_t(2 + 2 * edges) do return -1

	adjacency: [MAX_MATRIX]bool
	for edge := 0; edge < edges; edge += 1 {
		left := input[2 + 2 * edge]
		right := input[3 + 2 * edge]
		if left < 0 || left >= i64(vertices) || right < 0 || right >= i64(vertices) do return -1
		forward := int(left) * MAX_VERTICES + int(right)
		reverse := int(right) * MAX_VERTICES + int(left)
		if adjacency[forward] do return -1
		adjacency[forward] = true
		adjacency[reverse] = true
	}

	visited: [MAX_VERTICES]bool
	stack_vertex: [MAX_VERTICES]int
	stack_parent: [MAX_VERTICES]int
	for start := 0; start < vertices; start += 1 {
		if visited[start] do continue
		top := 1
		stack_vertex[0] = start
		stack_parent[0] = MAX_VERTICES
		visited[start] = true
		for top > 0 {
			top -= 1
			current := stack_vertex[top]
			parent := stack_parent[top]
			for neighbor := 0; neighbor < vertices; neighbor += 1 {
				if !adjacency[current * MAX_VERTICES + neighbor] || neighbor == parent do continue
				if visited[neighbor] do return 1
				visited[neighbor] = true
				stack_vertex[top] = neighbor
				stack_parent[top] = current
				top += 1
			}
		}
	}
	return 0
}
