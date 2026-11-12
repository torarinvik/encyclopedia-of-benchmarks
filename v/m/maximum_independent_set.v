module maximum_independent_set

const max_n = 22
const max_input = 465

fn mis_popcount(bits_value u64) int {
	mut bits := bits_value
	mut count := 0
	for bits != 0 { bits &= bits - u64(1); count++ }
	return count
}

fn mis_first_vertex(bits u64) int {
	for vertex in 0 .. max_n {
		if (bits & (u64(1) << vertex)) != 0 { return vertex }
	}
	return -1
}

fn mis_clique_cover_bound(adjacency [max_n]u64, remaining_value u64) int {
	mut remaining := remaining_value
	mut cliques := 0
	for remaining != 0 {
		cliques++
		mut candidates := remaining
		for candidates != 0 {
			vertex := mis_first_vertex(candidates)
			bit := u64(1) << vertex
			remaining &= ~bit
			candidates &= ~bit
			candidates &= adjacency[vertex]
		}
	}
	return cliques
}

fn mis_search(adjacency [max_n]u64, remaining u64, chosen int, mut best int) {
	if remaining == 0 { best = max(best, chosen); return }
	if chosen + mis_popcount(remaining) <= best { return }
	if chosen + mis_clique_cover_bound(adjacency, remaining) <= best { return }
	mut vertices := remaining
	mut branch := 0
	mut branch_degree := -1
	for vertices != 0 {
		vertex := mis_first_vertex(vertices)
		bit := u64(1) << vertex
		degree := mis_popcount(adjacency[vertex] & remaining)
		if degree > branch_degree { branch = vertex; branch_degree = degree }
		vertices &= ~bit
	}
	bit := u64(1) << branch
	mis_search(adjacency, remaining & ~bit & ~adjacency[branch], chosen + 1, mut best)
	mis_search(adjacency, remaining & ~bit, chosen, mut best)
}

@[export: 'maximum_independent_set']
pub fn maximum_independent_set(packed &i64, length usize) i64 {
	unsafe {
		if packed == nil || length < 2 || length > max_input { return -1 }
		n_value, m_value := packed[0], packed[1]
		if n_value < 0 || n_value > max_n { return -1 }
		max_edges := n_value * (n_value - 1) / 2
		if m_value < 0 || m_value > max_edges || length != usize(2 + 2 * m_value) { return -1 }
		mut adjacency := [max_n]u64{}
		for edge in 0 .. int(m_value) {
			u_value, v_value := packed[2 + 2 * edge], packed[3 + 2 * edge]
			if u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value { return -1 }
			u, v := int(u_value), int(v_value)
			v_bit := u64(1) << v
			if adjacency[u] & v_bit != 0 { return -1 }
			adjacency[u] |= v_bit
			adjacency[v] |= u64(1) << u
		}
		mut best := 0
		all_vertices := (u64(1) << int(n_value)) - u64(1)
		mis_search(adjacency, all_vertices, 0, mut best)
		return i64(best)
	}
}
