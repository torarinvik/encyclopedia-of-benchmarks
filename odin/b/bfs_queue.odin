package bfs_queue

import "core:c"

MAX_VERTEX_COUNT :: 64
MAX_EDGE_COUNT :: 2046
MAX_INPUT_LENGTH :: 4 + 2 * MAX_EDGE_COUNT

@(export)
bfs_queue :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_VERTEX_COUNT || input[3] < 0 || input[3] > MAX_EDGE_COUNT do return -1
	vertex_count := int(input[0])
	source_arg := input[1]
	target_arg := input[2]
	edge_count := int(input[3])
	if source_arg < 0 || source_arg >= i64(vertex_count) || target_arg < 0 ||
		target_arg >= i64(vertex_count) || int(length) != 4 + 2 * edge_count do return -1

	adjacency := [MAX_VERTEX_COUNT]u64{}
	for edge := 0; edge < edge_count; edge += 1 {
		left_arg := input[4 + 2 * edge]
		right_arg := input[5 + 2 * edge]
		if left_arg < 0 || right_arg < 0 || left_arg >= i64(vertex_count) || right_arg >= i64(vertex_count) do return -1
		left := int(left_arg)
		right := int(right_arg)
		adjacency[left] |= u64(1) << right
		adjacency[right] |= u64(1) << left
	}

	source := int(source_arg)
	target := int(target_arg)
	predecessor := [MAX_VERTEX_COUNT]int{}
	visited := [MAX_VERTEX_COUNT]bool{}
	queue := [MAX_VERTEX_COUNT]int{}
	for vertex := 0; vertex < vertex_count; vertex += 1 do predecessor[vertex] = -1
	predecessor[source] = source
	visited[source] = true
	head := 0
	tail := 1
	queue[0] = source
	found := source == target
	for head < tail && !found {
		current := queue[head]
		head += 1
		for neighbor := 0; neighbor < vertex_count; neighbor += 1 {
			if adjacency[current] & (u64(1) << neighbor) == 0 || visited[neighbor] do continue
			visited[neighbor] = true
			predecessor[neighbor] = current
			if neighbor == target { found = true; break }
			queue[tail] = neighbor
			tail += 1
		}
	}
	if !found {
		if output_capacity < 1 || output == nil do return -2
		output[0] = 0
		return 1
	}

	path := [MAX_VERTEX_COUNT]u8{}
	path_length := 0
	current := target
	for current != source {
		path[path_length] = u8(current)
		path_length += 1
		current = predecessor[current]
	}
	path[path_length] = u8(source)
	path_length += 1
	if output_capacity < c.size_t(path_length + 1) || output == nil do return -2
	output[0] = 1
	for index := 0; index < path_length; index += 1 do output[index + 1] = path[index]
	return i64(path_length + 1)
}
