package bondy_chvatal_hamiltonian_closure

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 28
MAX_INPUT_WORDS :: 59
MAX_OUTPUT_WORDS :: 10

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export, link_name="bondy_chvatal_hamiltonian_closure")
bondy_chvatal_hamiltonian_closure :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_WORDS) do return -1
	n_word, m_word := input[0], input[1]
	if n_word < 3 || n_word > MAX_VERTICES || m_word < 0 || m_word > MAX_EDGES do return -1
	n, m := int(n_word), int(m_word)
	if m > n * (n - 1) / 2 || length != c.size_t(2 + 2 * m) do return -1

	adjacency: [MAX_VERTICES][MAX_VERTICES]bool
	for edge := 0; edge < m; edge += 1 {
		u_word, v_word := input[2 + 2 * edge], input[3 + 2 * edge]
		if u_word < 0 || u_word >= n_word || v_word < 0 || v_word >= n_word || u_word == v_word do return -1
		u, v := int(u_word), int(v_word)
		if adjacency[u][v] do return -1
		adjacency[u][v] = true
		adjacency[v][u] = true
	}

	added := 0
	for {
		degree: [MAX_VERTICES]int
		for u := 0; u < n; u += 1 {
			for v := 0; v < n; v += 1 { if adjacency[u][v] { degree[u] += 1 } }
		}
		chosen_u, chosen_v := n, n
		for u := 0; u < n; u += 1 {
			if chosen_u < n do break
			for v := u + 1; v < n; v += 1 {
				if !adjacency[u][v] && degree[u] + degree[v] >= n {
					chosen_u, chosen_v = u, v
					break
				}
			}
		}
		if chosen_u == n do break
		adjacency[chosen_u][chosen_v] = true
		adjacency[chosen_v][chosen_u] = true
		added += 1
	}

	staged: [MAX_OUTPUT_WORDS]i64
	full_mask := (1 << n) - 1
	complete := true
	for u := 0; u < n; u += 1 {
		row := 0
		for v := 0; v < n; v += 1 { if adjacency[u][v] { row |= 1 << v } }
		staged[2 + u] = i64(row)
		if row != (full_mask ^ (1 << u)) { complete = false }
	}
	if complete { staged[0] = 1 }
	staged[1] = i64(added)

	output_bytes := c.size_t(2 + n) * 8
	if output == nil || capacity < output_bytes do return -2
	for word := 0; word < 2 + n; word += 1 { store_i64_le(output, word * 8, staged[word]) }
	return i64(output_bytes)
}
