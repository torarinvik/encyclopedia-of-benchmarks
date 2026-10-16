package graph_coloring_backtracking

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 2016

color_vertex :: proc "contextless" (vertex, count: int, adjacency: [^]bool, colors: [^]i64) -> bool {
	if vertex == count { return true }
	for color: i64 = 1; color <= i64(count); color += 1 {
		safe := true
		for neighbor := 0; neighbor < count; neighbor += 1 {
			if adjacency[vertex * MAX_VERTICES + neighbor] && colors[neighbor] == color {
				safe = false
				break
			}
		}
		if !safe { continue }
		colors[vertex] = color
		if color_vertex(vertex + 1, count, adjacency, colors) { return true }
		colors[vertex] = 0
	}
	return false
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
graph_coloring_backtracking :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 { return -1 }
	n_value, m_value := input[0], input[1]
	if n_value < 0 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
		length != 2 + 2 * c.size_t(m_value) { return -1 }
	n, m := int(n_value), int(m_value)
	adjacency: [MAX_VERTICES * MAX_VERTICES]bool
	for edge := 0; edge < m; edge += 1 {
		u_value, v_value := input[2 + 2 * edge], input[3 + 2 * edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
		u, v := int(u_value), int(v_value)
		adjacency[u * MAX_VERTICES + v] = true
		adjacency[v * MAX_VERTICES + u] = true
	}
	colors: [MAX_VERTICES]i64
	if !color_vertex(0, n, &adjacency[0], &colors[0]) { return -1 }
	colors_used: i64 = 0
	for vertex := 0; vertex < n; vertex += 1 { if colors[vertex] > colors_used { colors_used = colors[vertex] } }
	packed: [MAX_VERTICES + 2]i64
	packed[0] = n_value
	for vertex := 0; vertex < n; vertex += 1 { packed[vertex + 1] = colors[vertex] }
	packed[n + 1] = colors_used
	used, required := n + 2, (n + 2) * 8
	if output == nil || capacity < c.size_t(required) { return -2 }
	for index := 0; index < used; index += 1 { put_i64(output, index * 8, packed[index]) }
	return i64(required)
}
