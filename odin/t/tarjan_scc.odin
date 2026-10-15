package tarjan_scc

import "core:c"

MAX_VERTEX_COUNT :: 40
MAX_EDGE_COUNT :: 2047
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGE_COUNT

visit_vertex :: proc(adjacency: ^[MAX_VERTEX_COUNT]u64, on_stack: ^[MAX_VERTEX_COUNT]bool,
	stack: ^[MAX_VERTEX_COUNT]int, stack_length: ^int, discovery, low, component_id: ^[MAX_VERTEX_COUNT]int,
	vertex_count, vertex: int, time, component_count: ^int) {
	discovery[vertex] = time^
	low[vertex] = time^
	time^ += 1
	on_stack[vertex] = true
	stack[stack_length^] = vertex
	stack_length^ += 1
	for neighbor := 0; neighbor < vertex_count; neighbor += 1 {
		if adjacency[vertex] & (u64(1) << neighbor) == 0 do continue
		if discovery[neighbor] == -1 {
			visit_vertex(adjacency, on_stack, stack, stack_length, discovery, low, component_id,
				vertex_count, neighbor, time, component_count)
			if low[neighbor] < low[vertex] do low[vertex] = low[neighbor]
		} else if on_stack[neighbor] && discovery[neighbor] < low[vertex] {
			low[vertex] = discovery[neighbor]
		}
	}
	if low[vertex] == discovery[vertex] {
		for {
			stack_length^ -= 1
			member := stack[stack_length^]
			on_stack[member] = false
			component_id[member] = component_count^
			if member == vertex do break
		}
		component_count^ += 1
	}
}

encode_components :: proc(component_id: ^[MAX_VERTEX_COUNT]int, vertex_count, component_count: int,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	output_length := 1 + vertex_count + component_count
	if output_capacity < c.size_t(output_length) || output == nil do return -2
	output[0] = u8(component_count)
	position := 1
	for first := 0; first < vertex_count; first += 1 {
		id := component_id[first]
		emitted := false
		for earlier := 0; earlier < first; earlier += 1 {
			if component_id[earlier] == id do emitted = true
		}
		if emitted do continue
		component_size := 0
		for member := first; member < vertex_count; member += 1 {
			if component_id[member] == id do component_size += 1
		}
		output[position] = u8(component_size)
		position += 1
		for member := first; member < vertex_count; member += 1 {
			if component_id[member] == id {
				output[position] = u8(member)
				position += 1
			}
		}
	}
	return i64(output_length)
}

@(export)
tarjan_scc :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT do return -1
	vertex_count := int(input[0])
	edge_count := int(input[1])
	if int(length) != 2 + 2 * edge_count do return -1
	adjacency: [MAX_VERTEX_COUNT]u64
	for vertex := 0; vertex < MAX_VERTEX_COUNT; vertex += 1 { adjacency[vertex] = 0 }
	for edge := 0; edge < edge_count; edge += 1 {
		from_value := input[2 + 2 * edge]
		to_value := input[3 + 2 * edge]
		if from_value < 0 || to_value < 0 || from_value >= i64(vertex_count) || to_value >= i64(vertex_count) do return -1
		adjacency[int(from_value)] |= u64(1) << int(to_value)
	}
	on_stack: [MAX_VERTEX_COUNT]bool
	stack: [MAX_VERTEX_COUNT]int
	discovery: [MAX_VERTEX_COUNT]int
	low: [MAX_VERTEX_COUNT]int
	component_id: [MAX_VERTEX_COUNT]int
	for vertex := 0; vertex < MAX_VERTEX_COUNT; vertex += 1 {
		on_stack[vertex] = false
		discovery[vertex] = -1
		low[vertex] = 0
		component_id[vertex] = -1
	}
	stack_length, time, component_count := 0, 0, 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if discovery[vertex] == -1 do visit_vertex(&adjacency, &on_stack, &stack, &stack_length,
			&discovery, &low, &component_id, vertex_count, vertex, &time, &component_count)
	}
	return encode_components(&component_id, vertex_count, component_count, output, output_capacity)
}
