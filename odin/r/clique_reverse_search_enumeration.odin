package clique_reverse_search_enumeration

import "core:c"

MAX_N :: 8
MAX_INPUT :: MAX_N + 1
MAX_CLIQUES :: 256
MAX_OUTPUT_BYTES :: 8 + MAX_CLIQUES

visit :: proc(n: int, adjacency: [^]u16, clique: u16, masks: [^]u8, count: ^int) {
	masks[count^] = u8(clique)
	count^ += 1
	minimum := n
	for vertex := 0; vertex < n; vertex += 1 {
		if clique & (u16(1) << u16(vertex)) != 0 { minimum = vertex; break }
	}
	for vertex := 0; vertex < minimum; vertex += 1 {
		bit := u16(1) << u16(vertex)
		if clique & bit == 0 && adjacency[vertex] & clique == clique do visit(n, adjacency, clique | bit, masks, count)
	}
}

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
clique_reverse_search_enumeration :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	adjacency: [MAX_N]u16
	for vertex := 0; vertex < n; vertex += 1 {
		raw := input[vertex + 1]
		if raw < 0 || raw >= (i64(1) << n) || (raw & (i64(1) << vertex)) != 0 do return -1
		adjacency[vertex] = u16(raw)
	}
	for left := 0; left < n; left += 1 {
		for right := left + 1; right < n; right += 1 {
			edge_left := adjacency[left] & (u16(1) << right) != 0
			edge_right := adjacency[right] & (u16(1) << left) != 0
			if edge_left != edge_right do return -1
		}
	}
	masks: [MAX_CLIQUES]u8
	count := 0
	visit(n, &adjacency[0], 0, &masks[0], &count)
	required := c.size_t(8 + count)
	if output == nil || capacity < required do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for byte := 0; byte < MAX_OUTPUT_BYTES; byte += 1 { staged[byte] = 0 }
	store_i64_le(&staged[0], i64(count))
	for index := 0; index < count; index += 1 { staged[8 + index] = masks[index] }
	for byte := 0; byte < int(required); byte += 1 { output[byte] = staged[byte] }
	return i64(required)
}
