package mcoloring

import "core:c"

MAX_VERTICES :: 14
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(17)

find_root :: proc "contextless" (parent: [^]int, vertex_input: int) -> int {
	vertex := vertex_input
	for parent[vertex] != vertex {
		parent[vertex] = parent[parent[vertex]]
		vertex = parent[vertex]
	}
	return vertex
}

mcoloring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value, colors_value := input[0], input[1]
	if n_value < 0 || n_value > MAX_VERTICES || colors_value < 1 || colors_value > MAX_VERTICES do return -1
	n := int(n_value)
	if length != c.size_t(n+2) do return -1

	var masks: [MAX_VERTICES]u32
	var parent: [MAX_VERTICES]int
	valid_mask := u32(0)
	if n > 0 { valid_mask = (u32(1) << n) - 1 }
	for vertex in 0..<n {
		raw := input[vertex+2]
		if raw < 0 || u64(raw) > u64(valid_mask) do return -1
		masks[vertex] = u32(raw)
		if masks[vertex] & (u32(1) << vertex) != 0 do return -1
		parent[vertex] = vertex
	}
	for vertex in 0..<n {
		for neighbor in vertex+1..<n {
			edge := masks[vertex] & (u32(1) << neighbor) != 0
			if edge != (masks[neighbor] & (u32(1) << vertex) != 0) do return -1
			if edge {
				root_a := find_root(&parent[0], vertex)
				root_b := find_root(&parent[0], neighbor)
				if root_a == root_b do return -1
				parent[root_a] = root_b
			}
		}
	}

	var colors: [MAX_VERTICES]int
	var visited: [MAX_VERTICES]bool
	var queue: [MAX_VERTICES]int
	for vertex in 0..<n { colors[vertex] = 1 }
	maximum_color := 1
	for start in 0..<n {
		if visited[start] do continue
		head, tail := 0, 0
		visited[start] = true
		queue[tail] = start
		tail += 1
		for head < tail {
			vertex := queue[head]
			head += 1
			for neighbor in 0..<n {
				if masks[vertex] & (u32(1) << neighbor) == 0 do continue
				if colors[vertex] == colors[neighbor] { colors[neighbor] += 1 }
				if colors[vertex] > maximum_color { maximum_color = colors[vertex] }
				if colors[neighbor] > maximum_color { maximum_color = colors[neighbor] }
				if maximum_color > int(colors_value) do return 0
				if !visited[neighbor] {
					visited[neighbor] = true
					queue[tail] = neighbor
					tail += 1
				}
			}
		}
	}
	return 1
}
