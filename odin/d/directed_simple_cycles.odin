package directed_simple_cycles

import "core:c"

MAX_VERTICES :: 6
MAX_EDGES :: MAX_VERTICES * MAX_VERTICES
MAX_OUTPUT_BYTES :: 2786

@(export)
directed_simple_cycles :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	vertex_value := input[0]
	edge_value := input[1]
	if vertex_value < 0 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES do return -1
	vertices := int(vertex_value)
	edges := int(edge_value)
	if int(length) != 2 + 2*edges do return -1

	adjacency: [MAX_VERTICES * MAX_VERTICES]bool = {}
	for edge := 0; edge < edges; edge += 1 {
		source := input[2 + 2*edge]
		destination := input[3 + 2*edge]
		if source < 0 || source >= vertex_value || destination < 0 || destination >= vertex_value do return -1
		adjacency[int(source)*MAX_VERTICES + int(destination)] = true
	}

	scratch: [MAX_OUTPUT_BYTES]u8
	output_length := 0
	for start := 0; start < vertices; start += 1 {
		path: [MAX_VERTICES]int = {}
		next_neighbor: [MAX_VERTICES]int = {}
		visited: [MAX_VERTICES]bool = {}
		depth := 0
		path[0] = start
		visited[start] = true
		for {
			current := path[depth]
			if next_neighbor[depth] == vertices {
				visited[current] = false
				if depth == 0 do break
				depth -= 1
				continue
			}
			neighbor := next_neighbor[depth]
			next_neighbor[depth] += 1
			if !adjacency[current*MAX_VERTICES + neighbor] do continue
			if neighbor == start {
				for index := 0; index <= depth; index += 1 {
					scratch[output_length] = u8(path[index])
					output_length += 1
				}
				scratch[output_length] = u8(start)
				output_length += 1
			scratch[output_length] = 255
				output_length += 1
			} else if !visited[neighbor] {
				depth += 1
				path[depth] = neighbor
				next_neighbor[depth] = 0
				visited[neighbor] = true
			}
		}
		for vertex := 0; vertex < vertices; vertex += 1 {
			adjacency[start*MAX_VERTICES + vertex] = false
			adjacency[vertex*MAX_VERTICES + start] = false
		}
	}
	if output_length == 0 do return 0
	if output == nil || int(capacity) < output_length do return -2
	for index := 0; index < output_length; index += 1 { output[index] = scratch[index] }
	return i64(output_length)
}
