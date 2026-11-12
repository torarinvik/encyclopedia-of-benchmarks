package maximum_independent_set

import "core:c"

MAX_N :: 22
MAX_INPUT :: 465

Mis_Search :: struct {
	adjacency: [MAX_N]u64,
	best: int,
}

popcount :: proc "contextless" (bits_input: u64) -> int {
	bits := bits_input
	count := 0
	for bits != 0 { bits &= bits-1; count += 1 }
	return count
}

trailing_zeros :: proc "contextless" (value: u64) -> int {
	count := 0
	for (value & 1) == 0 { value >>= 1; count += 1 }
	return count
}

clique_cover_bound :: proc "contextless" (search: ^Mis_Search, remaining_input: u64) -> int {
	remaining := remaining_input
	cliques := 0
	for remaining != 0 {
		cliques += 1
		candidates := remaining
		for candidates != 0 {
			vertex := trailing_zeros(candidates)
			bit := u64(1)<<vertex
			remaining &= ~bit
			candidates &= ~bit
			candidates &= search.adjacency[vertex]
		}
	}
	return cliques
}

search_mis :: proc "contextless" (search: ^Mis_Search, remaining: u64, chosen: int) {
	if remaining == 0 { search.best = max(search.best, chosen); return }
	if chosen+popcount(remaining) <= search.best { return }
	if chosen+clique_cover_bound(search, remaining) <= search.best { return }
	branch := 0
	branch_degree := -1
	vertices := remaining
	for vertices != 0 {
		vertex := trailing_zeros(vertices)
		bit := u64(1)<<vertex
		degree := popcount(search.adjacency[vertex] & remaining)
		if degree > branch_degree { branch = vertex; branch_degree = degree }
		vertices &= ~bit
	}
	bit := u64(1)<<branch
	search_mis(search, remaining & ~bit & ~search.adjacency[branch], chosen+1)
	search_mis(search, remaining & ~bit, chosen)
}

@(export)
maximum_independent_set :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > c.size_t(MAX_INPUT) do return -1
	n_value, m_value := packed[0], packed[1]
	if n_value < 0 || n_value > MAX_N do return -1
	max_edges := n_value*(n_value-1)/2
	if m_value < 0 || m_value > max_edges || length != c.size_t(2+2*m_value) do return -1
	search := Mis_Search{}
	for edge := 0; edge < int(m_value); edge += 1 {
		u_value, v_value := packed[2+2*edge], packed[3+2*edge]
		if u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value do return -1
		u, v := int(u_value), int(v_value)
		v_bit := u64(1)<<v
		if search.adjacency[u]&v_bit != 0 do return -1
		search.adjacency[u] |= v_bit
		search.adjacency[v] |= u64(1)<<u
	}
	search_mis(&search, (u64(1)<<int(n_value))-1, 0)
	return i64(search.best)
}
