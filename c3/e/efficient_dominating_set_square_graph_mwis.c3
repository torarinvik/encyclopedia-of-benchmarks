module efficient_dominating_set_square_graph_mwis;

const usz MAX_VERTICES = 12;
const usz MAX_PARSEABLE_INPUT = 135;

fn long popcount64(ulong bits) {
    long count = 0;
    while (bits != 0) { bits &= bits - 1; count++; }
    return count;
}

fn void search_weighted_mis(ulong* square, long* weights, usz n,
                            ulong remaining, long current, long* best) {
    long upper_bound = current;
    for (usz vertex = 0; vertex < n; vertex++)
        if ((remaining & (ulong(1) << vertex)) != 0) upper_bound += weights[vertex];
    if (upper_bound <= *best) return;
    if (remaining == 0) { *best = current; return; }

    usz branch = 0;
    long branch_degree = -1;
    for (usz vertex = 0; vertex < n; vertex++) {
        if ((remaining & (ulong(1) << vertex)) == 0) continue;
        long degree = popcount64(square[vertex] & remaining);
        if (degree > branch_degree) { branch = vertex; branch_degree = degree; }
    }
    ulong bit = ulong(1) << branch;
    search_weighted_mis(square, weights, n, remaining & ~bit & ~square[branch],
                        current + weights[branch], best);
    search_weighted_mis(square, weights, n, remaining & ~bit, current, best);
}

fn long efficient_dominating_set_square_graph_mwis(long* input, usz length)
        @export("efficient_dominating_set_square_graph_mwis") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    long n_value = input[0], edge_count = input[1];
    if (n_value < 1 || n_value > 12) return -1;
    long maximum_edges = n_value * (n_value - 1) / 2;
    if (edge_count < 0 || edge_count > maximum_edges || length != 2 + 2 * (usz)edge_count) return -1;
    usz n = (usz)n_value;
    ulong[12] adjacency = {};
    for (usz edge = 0; edge < (usz)edge_count; edge++) {
        long u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= v_value || v_value >= n_value) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        ulong v_bit = ulong(1) << v;
        if ((adjacency[u] & v_bit) != 0) return -1;
        adjacency[u] |= v_bit;
        adjacency[v] |= ulong(1) << u;
    }

    ulong[12] square = {};
    long[12] weights = {};
    for (usz vertex = 0; vertex < n; vertex++) {
        square[vertex] = adjacency[vertex];
        for (usz neighbor = 0; neighbor < n; neighbor++)
            if ((adjacency[vertex] & (ulong(1) << neighbor)) != 0)
                square[vertex] |= adjacency[neighbor];
        square[vertex] &= ~(ulong(1) << vertex);
        weights[vertex] = popcount64(adjacency[vertex]) + 1;
    }
    long best = 0;
    ulong all_vertices = (ulong(1) << n) - 1;
    search_weighted_mis(&square[0], &weights[0], n, all_vertices, 0, &best);
    return best == n_value ? 1 : 0;
}
