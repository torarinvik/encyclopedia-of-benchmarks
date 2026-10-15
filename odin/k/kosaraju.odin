package kosaraju

import "core:c"

MAX_VERTEX_COUNT :: 40
MAX_EDGE_COUNT :: 2047
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGE_COUNT

fill_order :: proc(adjacency: ^[MAX_VERTEX_COUNT]u64, visited: ^[MAX_VERTEX_COUNT]bool,
	order: ^[MAX_VERTEX_COUNT]int, order_length: ^int, vertex_count, vertex: int) {
	visited[vertex] = true
	for neighbor := 0; neighbor < vertex_count; neighbor += 1 {
		if adjacency[vertex] & (u64(1) << neighbor) != 0 && !visited[neighbor] {
			fill_order(adjacency, visited, order, order_length, vertex_count, neighbor)
		}
	}
	order[order_length^] = vertex
	order_length^ += 1
}

collect_component :: proc(transpose: ^[MAX_VERTEX_COUNT]u64, visited: ^[MAX_VERTEX_COUNT]bool,
	component_id: ^[MAX_VERTEX_COUNT]int, vertex_count, vertex, id: int) {
	visited[vertex] = true
	component_id[vertex] = id
	for neighbor := 0; neighbor < vertex_count; neighbor += 1 {
		if transpose[vertex] & (u64(1) << neighbor) != 0 && !visited[neighbor] {
			collect_component(transpose, visited, component_id, vertex_count, neighbor, id)
		}
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
kosaraju :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT do return -1
	vertex_count := int(input[0])
	edge_count := int(input[1])
	if int(length) != 2 + 2 * edge_count do return -1
	adjacency: [MAX_VERTEX_COUNT]u64
	transpose: [MAX_VERTEX_COUNT]u64
	for vertex := 0; vertex < MAX_VERTEX_COUNT; vertex += 1 {
		adjacency[vertex] = 0
		transpose[vertex] = 0
	}
	for edge := 0; edge < edge_count; edge += 1 {
		from_value := input[2 + 2 * edge]
		to_value := input[3 + 2 * edge]
		if from_value < 0 || to_value < 0 || from_value >= i64(vertex_count) || to_value >= i64(vertex_count) do return -1
		from := int(from_value)
		to := int(to_value)
		adjacency[from] |= u64(1) << to
		transpose[to] |= u64(1) << from
	}
	visited: [MAX_VERTEX_COUNT]bool
	order: [MAX_VERTEX_COUNT]int
	order_length := 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if !visited[vertex] do fill_order(&adjacency, &visited, &order, &order_length, vertex_count, vertex)
	}
	for vertex := 0; vertex < MAX_VERTEX_COUNT; vertex += 1 { visited[vertex] = false }
	component_id: [MAX_VERTEX_COUNT]int
	for vertex := 0; vertex < MAX_VERTEX_COUNT; vertex += 1 { component_id[vertex] = -1 }
	component_count := 0
	for index := order_length; index > 0; index -= 1 {
		vertex := order[index - 1]
		if !visited[vertex] {
			collect_component(&transpose, &visited, &component_id, vertex_count, vertex, component_count)
			component_count += 1
		}
	}
	return encode_components(&component_id, vertex_count, component_count, output, output_capacity)
}
