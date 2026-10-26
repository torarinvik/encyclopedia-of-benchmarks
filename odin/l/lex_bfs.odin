package lex_bfs

import "core:c"

MAX_N :: 16
MAX_M :: 120
MAX_INPUT :: 243

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
lex_bfs :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n64, m64, start64 := input[0], input[1], input[2]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
		start64 < 0 || start64 >= n64 || length != c.size_t(3+2*m64) do return -1
	n, m, start := int(n64), int(m64), int(start64)
	adjacency: [MAX_N][MAX_N]bool
	for edge := 0; edge < m; edge += 1 {
		u64, v64 := input[3+2*edge], input[4+2*edge]
		if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
		u, v := int(u64), int(v64)
		if adjacency[u][v] do return -1
		adjacency[u][v], adjacency[v][u] = true, true
	}
	output_bytes := 8*n
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	labels: [MAX_N][MAX_N]i64
	label_len: [MAX_N]int
	order: [MAX_N]i64
	selected: [MAX_N]bool
	current := start
	for step := 0; step < n; step += 1 {
		if step > 0 {
			have_best := false
			for vertex := 0; vertex < n; vertex += 1 {
				if selected[vertex] do continue
				if !have_best { current = vertex; have_best = true; continue }
				shared := label_len[vertex]
				if label_len[current] < shared do shared = label_len[current]
				position, decided := 0, false
				for position < shared {
					if labels[vertex][position] != labels[current][position] {
						if labels[vertex][position] > labels[current][position] do current = vertex
						decided = true
						break
					}
					position += 1
				}
				if !decided && (label_len[vertex] > label_len[current] ||
					(label_len[vertex] == label_len[current] && vertex < current)) do current = vertex
			}
		}
		selected[current] = true
		order[step] = i64(current)
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if !adjacency[current][neighbor] || selected[neighbor] do continue
			for position := label_len[neighbor]; position > 0; position -= 1 {
				labels[neighbor][position] = labels[neighbor][position-1]
			}
			labels[neighbor][0] = i64(step)
			label_len[neighbor] += 1
		}
	}
	for index := 0; index < n; index += 1 do store_i64_le(output, 8*index, order[index])
	return i64(output_bytes)
}
