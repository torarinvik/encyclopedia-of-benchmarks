package online_bridge_finding

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 128
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGES + 1

Bridge_State :: struct {
	dsu_2ecc: [MAX_VERTICES]int,
	dsu_cc: [MAX_VERTICES]int,
	dsu_cc_size: [MAX_VERTICES]int,
	parent: [MAX_VERTICES]int,
	last_visit: [MAX_VERTICES]int,
	iteration: int,
	bridges: int,
}

find_2ecc :: proc "contextless" (state: ^Bridge_State, vertex: int) -> int {
	if vertex == -1 do return -1
	if state.dsu_2ecc[vertex] == vertex do return vertex
	state.dsu_2ecc[vertex] = find_2ecc(state, state.dsu_2ecc[vertex])
	return state.dsu_2ecc[vertex]
}

find_cc :: proc "contextless" (state: ^Bridge_State, vertex_input: int) -> int {
	vertex := find_2ecc(state, vertex_input)
	if state.dsu_cc[vertex] == vertex do return vertex
	state.dsu_cc[vertex] = find_cc(state, state.dsu_cc[vertex])
	return state.dsu_cc[vertex]
}

make_root :: proc "contextless" (state: ^Bridge_State, vertex_input: int) {
	root := find_2ecc(state, vertex_input)
	vertex := root
	child := -1
	for vertex != -1 {
		next := find_2ecc(state, state.parent[vertex])
		state.parent[vertex] = child
		state.dsu_cc[vertex] = root
		child = vertex
		vertex = next
	}
	state.dsu_cc_size[root] = state.dsu_cc_size[child]
}

merge_path :: proc "contextless" (state: ^Bridge_State, left_input, right_input: int) {
	state.iteration += 1
	path_left: [MAX_VERTICES]int
	path_right: [MAX_VERTICES]int
	left_length, right_length := 0, 0
	left, right := left_input, right_input
	lca := -1
	for lca == -1 {
		if left != -1 {
			left = find_2ecc(state, left)
			path_left[left_length] = left
			left_length += 1
			if state.last_visit[left] == state.iteration { lca = left; break }
			state.last_visit[left] = state.iteration
			left = state.parent[left]
		}
		if right != -1 {
			right = find_2ecc(state, right)
			path_right[right_length] = right
			right_length += 1
			if state.last_visit[right] == state.iteration { lca = right; break }
			state.last_visit[right] = state.iteration
			right = state.parent[right]
		}
	}
	for index := 0; index < left_length; index += 1 {
		vertex := path_left[index]
		state.dsu_2ecc[vertex] = lca
		if vertex == lca do break
		state.bridges -= 1
	}
	for index := 0; index < right_length; index += 1 {
		vertex := path_right[index]
		state.dsu_2ecc[vertex] = lca
		if vertex == lca do break
		state.bridges -= 1
	}
}

add_edge :: proc "contextless" (state: ^Bridge_State, left_input, right_input: int) {
	left := find_2ecc(state, left_input)
	right := find_2ecc(state, right_input)
	if left == right do return
	left_cc := find_cc(state, left)
	right_cc := find_cc(state, right)
	if left_cc != right_cc {
		state.bridges += 1
		if state.dsu_cc_size[left_cc] > state.dsu_cc_size[right_cc] {
			left, right = right, left
			left_cc, right_cc = right_cc, left_cc
		}
		make_root(state, left)
		state.parent[left] = right
		state.dsu_cc[left] = right
		state.dsu_cc_size[right_cc] += state.dsu_cc_size[left]
	} else {
		merge_path(state, left, right)
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
online_bridge_finding :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	raw_vertices, raw_edges := values[0], values[1]
	if raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES do return -1
	vertex_count, edge_count := int(raw_vertices), int(raw_edges)
	if length != c.size_t(2 + 2 * edge_count) do return -1
	for edge := 0; edge < edge_count; edge += 1 {
		left, right := values[2 + 2 * edge], values[3 + 2 * edge]
		if left < 0 || right < 0 || left >= raw_vertices || right >= raw_vertices do return -1
	}
	output_bytes := edge_count * 8
	if output_bytes > 0 && (output == nil || output_capacity < c.size_t(output_bytes)) do return -2

	state: Bridge_State
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		state.dsu_2ecc[vertex] = vertex
		state.dsu_cc[vertex] = vertex
		state.dsu_cc_size[vertex] = 1
		state.parent[vertex] = -1
	}
	for edge := 0; edge < edge_count; edge += 1 {
		add_edge(&state, int(values[2 + 2 * edge]), int(values[3 + 2 * edge]))
		store_i64_le(output, edge * 8, i64(state.bridges))
	}
	return i64(output_bytes)
}
