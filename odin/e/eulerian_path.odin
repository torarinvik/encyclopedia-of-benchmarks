package eulerian_path

import "core:c"

MAX_VERTICES :: 32
MAX_EDGES :: 256

put_i64 :: proc "contextless" (output: [^]u8, byte_offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte_offset + byte] = u8(bits >> u64(byte * 8))
	}
}

// Construct a directed Eulerian path with iterative Hierholzer traversal.
@(export)
eulerian_path :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	vertex_value := input[0]
	edge_value := input[1]
	if vertex_value < 0 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES do return -1
	vertices := int(vertex_value)
	edges := int(edge_value)
	if int(length) != 2 + 2 * edges do return -1

	adjacency: [MAX_VERTICES][MAX_EDGES]u8
	in_degree: [MAX_VERTICES]int
	out_degree: [MAX_VERTICES]int
	for edge := 0; edge < edges; edge += 1 {
		source := input[2 + 2 * edge]
		destination := input[3 + 2 * edge]
		if source < 0 || source >= vertex_value || destination < 0 || destination >= vertex_value do return -1
		source_index := int(source)
		destination_index := int(destination)
		adjacency[source_index][out_degree[source_index]] = u8(destination_index)
		out_degree[source_index] += 1
		in_degree[destination_index] += 1
	}
	if edges == 0 do return 0

	start := 0
	start_count := 0
	end_count := 0
	for vertex := 0; vertex < vertices; vertex += 1 {
		difference := out_degree[vertex] - in_degree[vertex]
		if difference == 1 {
			start = vertex
			start_count += 1
		} else if difference == -1 {
			end_count += 1
		} else if difference != 0 do return 0
	}
	if !((start_count == 0 && end_count == 0) || (start_count == 1 && end_count == 1)) do return 0
	if start_count == 0 {
		for start < vertices && out_degree[start] == 0 { start += 1 }
		if start == vertices do return 0
	}

	remaining: [MAX_VERTICES]int
	for vertex := 0; vertex < vertices; vertex += 1 { remaining[vertex] = out_degree[vertex] }
	stack: [MAX_EDGES + 1]int
	reverse_path: [MAX_EDGES + 1]i64
	top := 1
	path_count := 0
	stack[0] = start
	for top > 0 {
		current := stack[top - 1]
		if remaining[current] > 0 {
			remaining[current] -= 1
			next := int(adjacency[current][remaining[current]])
			stack[top] = next
			top += 1
		} else {
			top -= 1
			reverse_path[path_count] = i64(stack[top])
			path_count += 1
		}
	}
	if path_count != edges + 1 do return 0
	bytes := path_count * 8
	if output == nil || int(capacity) < bytes do return -2
	for index := 0; index < path_count; index += 1 {
		put_i64(output, index * 8, reverse_path[path_count - index - 1])
	}
	return i64(bytes)
}
