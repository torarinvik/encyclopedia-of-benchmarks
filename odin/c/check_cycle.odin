package check_cycle

import "core:c"

MAX_VERTICES :: 32
MAX_EDGES :: 256
MAX_MATRIX :: MAX_VERTICES * MAX_VERTICES

// Detect directed cycles with iterative three-color depth-first search.
@(export)
check_cycle :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	vertices := int(input[0])
	edges := int(input[1])
	if length != c.size_t(2 + 2 * edges) do return -1

	adjacency: [MAX_MATRIX]bool
	for edge := 0; edge < edges; edge += 1 {
		origin := input[2 + 2 * edge]
		destination := input[3 + 2 * edge]
		if origin < 0 || origin >= i64(vertices) || destination < 0 || destination >= i64(vertices) do return -1
		adjacency[int(origin) * MAX_VERTICES + int(destination)] = true
	}

	color: [MAX_VERTICES]int
	stack: [MAX_VERTICES]int
	next_neighbor: [MAX_VERTICES]int
	for start := 0; start < vertices; start += 1 {
		if color[start] != 0 do continue
		top := 1
		stack[0] = start
		next_neighbor[0] = 0
		color[start] = 1
		for top > 0 {
			frame := top - 1
			current := stack[frame]
			for next_neighbor[frame] < vertices && !adjacency[current * MAX_VERTICES + next_neighbor[frame]] { next_neighbor[frame] += 1 }
			if next_neighbor[frame] == vertices {
				color[current] = 2
				top -= 1
				continue
			}
			neighbor := next_neighbor[frame]
			next_neighbor[frame] += 1
			if color[neighbor] == 1 do return 1
			if color[neighbor] == 0 {
				color[neighbor] = 1
				stack[top] = neighbor
				next_neighbor[top] = 0
				top += 1
			}
		}
	}
	return 0
}
