package graph_coloring

import "core:c"

MAX_VERTICES :: 8
MAX_COLORS :: 4
MAX_VALIDATION_LENGTH :: 11
OUTPUT_BYTES :: 8

count_from :: proc "contextless" (masks: [MAX_VERTICES]u8,
	colors: [MAX_VERTICES]u8, vertex_count, color_count, vertex: int) -> i64 {
	if vertex == vertex_count do return 1
	count := i64(0)
	for color := 0; color < color_count; color += 1 {
		safe := true
		for prior := 0; prior < vertex; prior += 1 {
			if (masks[vertex] & u8(1 << prior)) != 0 && int(colors[prior]) == color {
				safe = false
				break
			}
		}
		if safe {
			next_colors := colors
			next_colors[vertex] = u8(color)
			count += count_from(masks, next_colors, vertex_count, color_count, vertex + 1)
		}
	}
	return count
}

put_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < OUTPUT_BYTES; byte += 1 {
		output[byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
graph_coloring :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_VALIDATION_LENGTH do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_VERTICES || m64 < 1 || m64 > MAX_COLORS do return -1
	n, m := int(n64), int(m64)
	if length != c.size_t(n + 2) do return -1

	var masks: [MAX_VERTICES]u8
	var colors: [MAX_VERTICES]u8
	mask_limit := i64(1) << n
	for vertex := 0; vertex < n; vertex += 1 {
		row := input[2 + vertex]
		if row < 0 || row >= mask_limit do return -1
		masks[vertex] = u8(row)
		if (masks[vertex] & u8(1 << vertex)) != 0 do return -1
	}
	for vertex := 0; vertex < n; vertex += 1 {
		for neighbor := 0; neighbor < n; neighbor += 1 {
			edge := (masks[vertex] & u8(1 << neighbor)) != 0
			reverse_edge := (masks[neighbor] & u8(1 << vertex)) != 0
			if edge != reverse_edge do return -1
		}
	}
	if output == nil || capacity < OUTPUT_BYTES do return -2
	count := count_from(masks, colors, n, m, 0)
	put_i64_le(output, count)
	return OUTPUT_BYTES
}
