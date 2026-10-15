package articulation_points

import "core:c"

MAX_VERTEX_COUNT :: 64
MAX_EDGE_COUNT :: 2047
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGE_COUNT

Graph_State :: struct {
	adjacency: [MAX_VERTEX_COUNT]u64,
	discovery: [MAX_VERTEX_COUNT]i64,
	low: [MAX_VERTEX_COUNT]i64,
	parent: [MAX_VERTEX_COUNT]i64,
	is_articulation: [MAX_VERTEX_COUNT]bool,
}

visit_vertex :: proc(state: ^Graph_State, vertex_count, vertex: int, time: ^int) {
	state.discovery[vertex] = i64(time^)
	state.low[vertex] = i64(time^)
	time^ += 1
	child_count := 0
	for neighbor := 0; neighbor < vertex_count; neighbor += 1 {
		if state.adjacency[vertex] & (u64(1) << neighbor) == 0 do continue
		if state.discovery[neighbor] == -1 {
			state.parent[neighbor] = i64(vertex)
			child_count += 1
			visit_vertex(state, vertex_count, neighbor, time)
			if state.low[neighbor] < state.low[vertex] do state.low[vertex] = state.low[neighbor]
			if state.parent[vertex] == -1 && child_count > 1 do state.is_articulation[vertex] = true
			if state.parent[vertex] != -1 && state.low[neighbor] >= state.discovery[vertex] do state.is_articulation[vertex] = true
		} else if i64(neighbor) != state.parent[vertex] && state.discovery[neighbor] < state.low[vertex] {
			state.low[vertex] = state.discovery[neighbor]
		}
	}
}

@(export)
articulation_points :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT do return -1
	vertex_count := int(input[0])
	edge_count := int(input[1])
	if int(length) != 2 + 2 * edge_count do return -1
	state := Graph_State{}
	for edge := 0; edge < edge_count; edge += 1 {
		left_value := input[2 + 2 * edge]
		right_value := input[3 + 2 * edge]
		if left_value < 0 || right_value < 0 || left_value >= i64(vertex_count) || right_value >= i64(vertex_count) do return -1
		left := int(left_value)
		right := int(right_value)
		state.adjacency[left] |= u64(1) << right
		state.adjacency[right] |= u64(1) << left
	}
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		state.discovery[vertex] = -1
		state.parent[vertex] = -1
	}
	time := 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if state.discovery[vertex] == -1 do visit_vertex(&state, vertex_count, vertex, &time)
	}
	point_count := 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if state.is_articulation[vertex] do point_count += 1
	}
	if output_capacity < c.size_t(point_count) || (point_count != 0 && output == nil) do return -2
	position := 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if state.is_articulation[vertex] { output[position] = u8(vertex); position += 1 }
	}
	return i64(point_count)
}
