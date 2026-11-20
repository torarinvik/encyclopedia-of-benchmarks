package dsatur_greedy_coloring

import "core:c"

MAX_VERTICES :: 12
MAX_EDGES :: 66
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(135)

bit_count :: proc "contextless" (value: u16) -> int {
	mask := value
	count := 0
	for mask != 0 {
		count += 1
		mask &= mask - 1
	}
	return count
}

@(export)
dsatur_greedy_coloring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	vertex_value := input[0]
	edge_value := input[1]
	if vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES do return -1
	n := int(vertex_value)
	m := int(edge_value)
	if length != c.size_t(2+2*m) do return -1

	var adjacency: [MAX_VERTICES]u16
	for edge := 0; edge < m; edge += 1 {
		u_value := input[2+2*edge]
		v_value := input[3+2*edge]
		if u_value < 0 || v_value <= u_value || v_value >= vertex_value do return -1
		u := int(u_value)
		v := int(v_value)
		v_bit := u16(1) << u16(v)
		if (adjacency[u] & v_bit) != 0 do return -1
		adjacency[u] |= v_bit
		adjacency[v] |= u16(1) << u16(u)
	}

	var colors: [MAX_VERTICES]int
	var saturation_colors: [MAX_VERTICES]u16
	var residual_degree: [MAX_VERTICES]int
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 { colors[vertex] = -1 }
	for vertex := 0; vertex < n; vertex += 1 { residual_degree[vertex] = bit_count(adjacency[vertex]) }

	color_count := 0
	for _ in 0..<n {
		selected := -1
		selected_saturation := -1
		selected_degree := -1
		for vertex := 0; vertex < n; vertex += 1 {
			if colors[vertex] >= 0 do continue
			saturation := bit_count(saturation_colors[vertex])
			degree := residual_degree[vertex]
			if selected < 0 || saturation > selected_saturation ||
				(saturation == selected_saturation && degree > selected_degree) ||
				(saturation == selected_saturation && degree == selected_degree && vertex < selected) {
				selected = vertex
				selected_saturation = saturation
				selected_degree = degree
			}
		}

		used_colors := saturation_colors[selected]
		color := 0
		for color < MAX_VERTICES && (used_colors & (u16(1) << u16(color))) != 0 { color += 1 }
		if color >= MAX_VERTICES do return -1
		colors[selected] = color
		if color+1 > color_count { color_count = color+1 }
		color_bit := u16(1) << u16(color)
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if colors[neighbor] < 0 && (adjacency[selected] & (u16(1) << u16(neighbor))) != 0 {
				residual_degree[neighbor] -= 1
				saturation_colors[neighbor] |= color_bit
			}
		}
	}

	packed := i64(color_count) << 48
	for vertex := 0; vertex < n; vertex += 1 { packed |= i64(colors[vertex]) << u64(4*vertex) }
	return packed
}
