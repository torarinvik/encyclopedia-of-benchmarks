module maximum_independent_set;

const usz MAX_N = 22;
const usz MAX_INPUT = 465;

fn long popcount(ulong bits) {
    long count = 0;
    while (bits != 0) { bits &= bits - 1; count += 1; }
    return count;
}

fn usz first_vertex(ulong bits) {
    usz vertex = 0;
    while ((bits & 1ul) == 0) { bits >>= 1; vertex += 1; }
    return vertex;
}

fn long clique_cover_bound(ulong* adjacency, ulong remaining) {
    long cliques = 0;
    while (remaining != 0) {
        cliques += 1;
        ulong candidates = remaining;
        while (candidates != 0) {
            ulong bit = candidates & (~candidates + 1ul);
            usz vertex = first_vertex(bit);
            remaining &= ~bit;
            candidates &= ~bit;
            candidates &= adjacency[vertex];
        }
    }
    return cliques;
}

fn void search_mis(ulong* adjacency, ulong remaining, long chosen, long* best) {
    if (remaining == 0) { if (chosen > *best) *best = chosen; return; }
    if (chosen + popcount(remaining) <= *best) return;
    if (chosen + clique_cover_bound(adjacency, remaining) <= *best) return;
    usz branch = 0;
    long branch_degree = -1;
    for (usz vertex = 0; vertex < MAX_N; vertex += 1) {
        ulong bit = 1ul << vertex;
        if ((remaining & bit) != 0) {
            long degree = popcount(adjacency[vertex] & remaining);
            if (degree > branch_degree) { branch = vertex; branch_degree = degree; }
        }
    }
    ulong bit = 1ul << branch;
    search_mis(adjacency, remaining & ~bit & ~adjacency[branch], chosen + 1, best);
    search_mis(adjacency, remaining & ~bit, chosen, best);
}

long maximum_independent_set(long* packed, usz length) @export("maximum_independent_set") {
    if (packed == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = packed[0], m_value = packed[1];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    long max_edges = n_value * (n_value - 1) / 2;
    if (m_value < 0 || m_value > max_edges || length != 2 + 2 * (usz)m_value) return -1;
    usz n = (usz)n_value;
    ulong[MAX_N] adjacency = zeroed;
    for (usz edge = 0; edge < (usz)m_value; edge += 1) {
        long u_value = packed[2 + 2 * edge], v_value = packed[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        ulong v_bit = 1ul << v;
        if ((adjacency[u] & v_bit) != 0) return -1;
        adjacency[u] |= v_bit;
        adjacency[v] |= 1ul << u;
    }
    long best = 0;
    ulong all_vertices = (1ul << n) - 1ul;
    search_mis(&adjacency[0], all_vertices, 0, &best);
    return best;
}
