package welsh_powell

import "core:c"

MAX_VERTICES :: 32
MAX_EDGE_PAIRS :: 512
MAX_VALIDATION_LENGTH :: 2 + 2 * MAX_EDGE_PAIRS + 1
OUTPUT_BYTES_PER_VERTEX :: 8

vertex_bit :: proc "contextless" (vertex: int) -> u64 {
	return u64(1) << u64(vertex)
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < OUTPUT_BYTES_PER_VERTEX; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
welsh_powell :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_VALIDATION_LENGTH do return -1
	n64, edge_count64 := input[0], input[1]
	if n64 < 0 || n64 > MAX_VERTICES || edge_count64 < 0 || edge_count64 > MAX_EDGE_PAIRS do return -1
	n, edge_count := int(n64), int(edge_count64)
	if length != c.size_t(2 + 2 * edge_count) do return -1

	var adjacency: [MAX_VERTICES]u64
	for edge := 0; edge < edge_count; edge += 1 {
		left64, right64 := input[2 + 2 * edge], input[3 + 2 * edge]
		if left64 < 0 || left64 >= n64 || right64 < 0 || right64 >= n64 || left64 == right64 do return -1
		left, right := int(left64), int(right64)
		adjacency[left] |= vertex_bit(right)
		adjacency[right] |= vertex_bit(left)
	}

	output_bytes := n * OUTPUT_BYTES_PER_VERTEX
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	var degrees: [MAX_VERTICES]int
	var order: [MAX_VERTICES]int
	var colors: [MAX_VERTICES]i64
	for vertex := 0; vertex < n; vertex += 1 {
		colors[vertex] = -1
		order[vertex] = vertex
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if adjacency[vertex] & vertex_bit(neighbor) != 0 do degrees[vertex] += 1
		}
	}

	// Stable descending degree order keeps equal-degree vertices by index.
	for index := 1; index < n; index += 1 {
		key := order[index]
		position := index
		for position > 0 && degrees[order[position - 1]] < degrees[key] {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = key
	}

	colored_vertices: u64 = 0
	for index := 0; index < n; index += 1 {
		vertex := order[index]
		if colors[vertex] >= 0 do continue
		used_colors: u64 = 0
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if adjacency[vertex] & vertex_bit(neighbor) != 0 && colors[neighbor] >= 0 {
				used_colors |= vertex_bit(int(colors[neighbor]))
			}
		}
		color := 0
		for used_colors & vertex_bit(color) != 0 { color += 1 }
		colors[vertex] = i64(color)
		colored_vertices |= vertex_bit(vertex)
		for other_index := 0; other_index < n; other_index += 1 {
			other := order[other_index]
			if colors[other] < 0 && adjacency[other] & colored_vertices == 0 {
				colors[other] = i64(color)
				colored_vertices |= vertex_bit(other)
			}
		}
	}

	for vertex := 0; vertex < n; vertex += 1 {
		put_i64_le(output, vertex * OUTPUT_BYTES_PER_VERTEX, colors[vertex])
	}
	return i64(output_bytes)
}
