package strong_orientation

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 128
MAX_ARCS :: 2 * MAX_EDGES
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGES + 1

Graph_State :: struct {
	head: [MAX_VERTICES]int,
	tail: [MAX_VERTICES]int,
	to: [MAX_ARCS]int,
	next: [MAX_ARCS]int,
	arc_edge: [MAX_ARCS]int,
	edge_u: [MAX_EDGES]int,
	edge_used: [MAX_EDGES]bool,
	direction: [MAX_EDGES]int,
	discovery: [MAX_VERTICES]int,
	low: [MAX_VERTICES]int,
	timer: int,
	bridges: int,
}

append_arc :: proc "contextless" (state: ^Graph_State, from, target, edge: int, arc_count: ^int) {
	arc := arc_count^
	arc_count^ += 1
	state.to[arc] = target
	state.arc_edge[arc] = edge
	state.next[arc] = -1
	if state.head[from] == -1 do state.head[from] = arc
	else do state.next[state.tail[from]] = arc
	state.tail[from] = arc
}

visit :: proc "contextless" (state: ^Graph_State, vertex: int) {
	state.discovery[vertex] = state.timer
	state.low[vertex] = state.timer
	state.timer += 1
	arc := state.head[vertex]
	for arc != -1 {
		next_arc := state.next[arc]
		edge := state.arc_edge[arc]
		if !state.edge_used[edge] {
			state.edge_used[edge] = true
			if vertex == state.edge_u[edge] do state.direction[edge] = 1
			else do state.direction[edge] = -1
			neighbor := state.to[arc]
			if state.discovery[neighbor] == -1 {
				visit(state, neighbor)
				if state.low[neighbor] < state.low[vertex] do state.low[vertex] = state.low[neighbor]
				if state.low[neighbor] > state.discovery[vertex] do state.bridges += 1
			} else if state.discovery[neighbor] < state.low[vertex] {
				state.low[vertex] = state.discovery[neighbor]
			}
		}
		arc = next_arc
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
strong_orientation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	raw_vertices, raw_edges := input[0], input[1]
	if raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES do return -1
	vertex_count, edge_count := int(raw_vertices), int(raw_edges)
	if int(length) != 2 + 2 * edge_count do return -1
	for edge := 0; edge < edge_count; edge += 1 {
		left, right := input[2 + 2 * edge], input[3 + 2 * edge]
		if left < 0 || right < 0 || left >= raw_vertices || right >= raw_vertices do return -1
	}
	output_bytes := 8 * (edge_count + 1)
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	state := Graph_State{}
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 {
		state.head[vertex] = -1
		state.tail[vertex] = -1
		state.discovery[vertex] = -1
	}
	arc_count := 0
	for edge := 0; edge < edge_count; edge += 1 {
		left, right := int(input[2 + 2 * edge]), int(input[3 + 2 * edge])
		state.edge_u[edge] = left
		append_arc(&state, left, right, edge, &arc_count)
		append_arc(&state, right, left, edge, &arc_count)
	}
	components := 0
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if state.discovery[vertex] == -1 {
			components += 1
			visit(&state, vertex)
		}
	}
	store_i64_le(output, 0, i64(components + state.bridges))
	for edge := 0; edge < edge_count; edge += 1 {
		store_i64_le(output, 8 * (edge + 1), i64(state.direction[edge]))
	}
	return i64(output_bytes)
}
