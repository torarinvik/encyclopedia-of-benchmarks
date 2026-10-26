package permutation_shortcut_index

import "core:c"

MAX_N :: 16
MAX_QUERIES :: 16
MAX_INPUT :: 52

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

is_marked :: proc(bitmap: u32, vertex: int) -> bool {
	return (bitmap & (u32(1) << u32(vertex))) != 0
}

shortcut_inverse :: proc(target, n: int, successor: [^]int, bitmap: u32, shortcuts: [^]int) -> int {
	marker := target
	steps := 0
	for steps < n && !is_marked(bitmap, marker) {
		marker = successor[marker]
		steps += 1
	}
	if !is_marked(bitmap, marker) {
		previous := target
		current := successor[target]
		for current != target { previous = current; current = successor[current] }
		return previous
	}
	rank := 0
	for vertex := 0; vertex < marker; vertex += 1 { if is_marked(bitmap, vertex) { rank += 1 } }
	current := shortcuts[rank]
	previous := current
	current = successor[current]
	for steps = 0; steps < n; steps += 1 {
		if current == target { return previous }
		previous = current
		current = successor[current]
	}
	return -1
}

permutation_shortcut_index :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n_raw, stride_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_N || stride_raw < 1 || stride_raw > MAX_N do return -1
	n, stride := int(n_raw), int(stride_raw)
	query_at := 2 + n
	if length <= c.size_t(query_at) do return -1
	query_raw := input[query_at]
	if query_raw < 0 || query_raw > MAX_QUERIES || length != c.size_t(query_at + 1 + 2 * int(query_raw)) do return -1
	query_count := int(query_raw)
	successor: [MAX_N]int
	seen: [MAX_N]bool
	for vertex := 0; vertex < n; vertex += 1 {
		value := input[2 + vertex]
		if value < 1 || value > n_raw || seen[int(value - 1)] do return -1
		seen[int(value - 1)] = true
		successor[vertex] = int(value - 1)
	}
	for query := 0; query < query_count; query += 1 {
		op := input[query_at + 1 + 2 * query]
		index := input[query_at + 2 + 2 * query]
		if (op != 0 && op != 1) || index < 1 || index > n_raw do return -1
	}
	visited: [MAX_N]bool
	back_pointer: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { back_pointer[vertex] = -1 }
	bitmap: u32 = 0
	for start := 0; start < n; start += 1 {
		if visited[start] do continue
		cycle: [MAX_N]int
		cycle_length := 0
		current := start
		for !visited[current] {
			visited[current] = true
			cycle[cycle_length] = current
			cycle_length += 1
			current = successor[current]
		}
		if cycle_length >= stride {
			for offset := 0; offset < cycle_length; offset += stride {
				vertex := cycle[offset]
				bitmap |= u32(1) << u32(vertex)
				back_offset := (offset - stride) % cycle_length
				if back_offset < 0 { back_offset += cycle_length }
				back_pointer[vertex] = cycle[back_offset]
			}
		}
	}
	shortcuts: [MAX_N]int
	shortcut_count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		if is_marked(bitmap, vertex) { shortcuts[shortcut_count] = back_pointer[vertex]; shortcut_count += 1 }
	}
	answers: [MAX_QUERIES]i64
	for query := 0; query < query_count; query += 1 {
		op := input[query_at + 1 + 2 * query]
		target := int(input[query_at + 2 + 2 * query]) - 1
		answer := 0
		if op == 0 { answer = successor[target] } else { answer = shortcut_inverse(target, n, &successor[0], bitmap, &shortcuts[0]) }
		if answer < 0 do return -1
		answers[query] = i64(answer + 1)
	}
	bytes := query_count * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for query := 0; query < query_count; query += 1 { store_i64_le(output, query * 8, answers[query]) }
	return i64(bytes)
}
