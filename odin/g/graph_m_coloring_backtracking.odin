package graph_m_coloring_backtracking

import "core:c"

MAX_VERTICES :: 12

assign_colors :: proc "contextless" (input: [^]i64, count, max_colors, vertex: int,
		colors: [^]i64) -> bool {
	if vertex == count { return true }
	for color := 0; color < max_colors; color += 1 {
		safe := true
		for neighbor := 0; neighbor < count; neighbor += 1 {
			if input[2 + vertex * count + neighbor] == 1 && colors[neighbor] == i64(color) {
				safe = false
				break
			}
		}
		if !safe { continue }
		colors[vertex] = i64(color)
		if assign_colors(input, count, max_colors, vertex + 1, colors) { return true }
		colors[vertex] = -1
	}
	return false
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
graph_m_coloring_backtracking :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 { return -1 }
	n_value, max_colors_value := input[0], input[1]
	if n_value < 0 || n_value > MAX_VERTICES || max_colors_value < 0 || max_colors_value > MAX_VERTICES { return -1 }
	n, max_colors := int(n_value), int(max_colors_value)
	if length != 2 + c.size_t(n * n) { return -1 }
	for row := 0; row < n; row += 1 {
		if input[2 + row * n + row] != 0 { return -1 }
		for column := 0; column < n; column += 1 {
			cell := input[2 + row * n + column]
			if (cell != 0 && cell != 1) || cell != input[2 + column * n + row] { return -1 }
		}
	}
	colors: [MAX_VERTICES]i64
	for vertex := 0; vertex < n; vertex += 1 { colors[vertex] = -1 }
	if !assign_colors(input, n, max_colors, 0, &colors[0]) { return 0 }
	required := n * 8
	if required == 0 { return 0 }
	if output == nil || capacity < c.size_t(required) { return -2 }
	for vertex := 0; vertex < n; vertex += 1 { put_i64(output, vertex * 8, colors[vertex]) }
	return i64(required)
}
