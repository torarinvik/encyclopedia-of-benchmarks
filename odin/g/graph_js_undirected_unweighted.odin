package graph_js_undirected_unweighted

import "core:c"

MAX_VERTICES :: 26
MAX_EDGES :: 256
MAX_DEGREE :: 512
MAX_INPUT_LENGTH :: 541
MAX_OUTPUT_VALUES :: 645
MAX_QUEUE :: 513

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
graph_js_undirected_unweighted :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_VERTICES do return -1
	vertex_count := int(input[0])
	if int(length) < 1+vertex_count+2 do return -1

	var vertices: [MAX_VERTICES]int
	var declared: [MAX_VERTICES]bool
	for index := 0; index < vertex_count; index += 1 {
		value := input[1+index]
		if value < 97 || value > 122 do return -1
		vertex := int(value - 97)
		if declared[vertex] do return -1
		declared[vertex] = true
		vertices[index] = vertex
	}
	edge_count_offset := 1+vertex_count
	raw_edge_count := input[edge_count_offset]
	if raw_edge_count < 0 || raw_edge_count > MAX_EDGES do return -1
	edge_count := int(raw_edge_count)
	if int(length) != 1+vertex_count+1+2*edge_count+1 do return -1

	var adjacency: [MAX_VERTICES*MAX_DEGREE]u8
	var degree: [MAX_VERTICES]int
	position := edge_count_offset+1
	for _ := 0; _ < edge_count; _ += 1 {
		left_value, right_value := input[position], input[position+1]
		position += 2
		if left_value < 97 || left_value > 122 || right_value < 97 || right_value > 122 do return -1
		left, right := int(left_value-97), int(right_value-97)
		if declared[left] && declared[right] {
			if degree[left] >= MAX_DEGREE || degree[right] >= MAX_DEGREE do return -1
			adjacency[left*MAX_DEGREE+degree[left]] = u8(right)
			degree[left] += 1
			adjacency[right*MAX_DEGREE+degree[right]] = u8(left)
			degree[right] += 1
		}
	}
	start_value := input[position]
	if start_value < 97 || start_value > 122 do return -1
	start := int(start_value-97)
	if !declared[start] do return -1

	var encoded_values: [MAX_OUTPUT_VALUES]i64
	result_length := 0
	encoded_values[result_length] = i64(vertex_count)
	result_length += 1
	for index := 0; index < vertex_count; index += 1 {
		vertex := vertices[index]
	encoded_values[result_length] = i64(97+vertex)
	encoded_values[result_length+1] = i64(degree[vertex])
	result_length += 2
	for edge := 0; edge < degree[vertex]; edge += 1 {
		encoded_values[result_length] = i64(97+int(adjacency[vertex*MAX_DEGREE+edge]))
		result_length += 1
	}
	}

	var visited: [MAX_VERTICES]bool
	var queue: [MAX_QUEUE]int
	var levels: [MAX_QUEUE]int
	bfs_count_slot := result_length
	result_length += 1
	head := 0
	tail := 1
	queue[0] = start
	levels[0] = 0
	bfs_count := 0
	for head < tail {
		vertex := queue[head]
		level := levels[head]
		head += 1
		if visited[vertex] do continue
		visited[vertex] = true
		encoded_values[result_length] = i64(97+vertex)
		encoded_values[result_length+1] = i64(level)
		result_length += 2
		bfs_count += 1
		for edge := 0; edge < degree[vertex]; edge += 1 {
			queue[tail] = int(adjacency[vertex*MAX_DEGREE+edge])
			levels[tail] = level+1
			tail += 1
		}
	}
	encoded_values[bfs_count_slot] = i64(bfs_count)

	for index := 0; index < MAX_VERTICES; index += 1 { visited[index] = false }
	dfs_count_slot := result_length
	result_length += 1
	var stack_vertices: [MAX_VERTICES]int
	var stack_next_edge: [MAX_VERTICES]int
	stack_depth := 1
	stack_vertices[0] = start
	visited[start] = true
	encoded_values[result_length] = i64(97+start)
	result_length += 1
	dfs_count := 1
	for stack_depth > 0 {
		top := stack_depth-1
		vertex := stack_vertices[top]
		if stack_next_edge[top] >= degree[vertex] {
			stack_depth -= 1
			continue
		}
		edge := stack_next_edge[top]
		stack_next_edge[top] += 1
		neighbor := int(adjacency[vertex*MAX_DEGREE+edge])
		if !visited[neighbor] {
			visited[neighbor] = true
			encoded_values[result_length] = i64(97+neighbor)
			result_length += 1
			dfs_count += 1
			stack_vertices[stack_depth] = neighbor
			stack_next_edge[stack_depth] = 0
			stack_depth += 1
		}
	}
	encoded_values[dfs_count_slot] = i64(dfs_count)

	output_bytes := result_length*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < result_length; index += 1 { store_i64_le(output, 8*index, encoded_values[index]) }
	return i64(output_bytes)
}
