module minimum_dominating_set_branch_bound;

const usz MAX_N = 12;
const usz MAX_INPUT = 135;

fn long popcount(ulong bits) {
    long count = 0;
    while (bits != 0) { bits &= bits - 1; count += 1; }
    return count;
}

fn long search_mds(ulong* closed, usz n, ulong full, ulong covered, long chosen, long best) {
    if (chosen >= best) return best;
    if (covered == full) return chosen;
    ulong uncovered = full & ~covered;
    long uncovered_count = popcount(uncovered);
    long maximum_gain = 0;
    for (usz v = 0; v < n; v += 1) {
        long gain = popcount(closed[v] & uncovered);
        if (gain > maximum_gain) maximum_gain = gain;
    }
    long lower_bound = (uncovered_count + maximum_gain - 1) / maximum_gain;
    if (chosen + lower_bound >= best) return best;

    usz branch = 0;
    long branch_degree = (long)MAX_N + 1;
    for (usz v = 0; v < n; v += 1) {
        if ((uncovered & (1ul << v)) != 0) {
            long degree = popcount(closed[v]);
            if (degree < branch_degree) { branch = v; branch_degree = degree; }
        }
    }
    usz[MAX_N] candidates = zeroed;
    long[MAX_N] gains = zeroed;
    usz count = 0;
    for (usz v = 0; v < n; v += 1) {
        if ((closed[branch] & (1ul << v)) == 0) continue;
        long gain = popcount(closed[v] & uncovered);
        usz pos = count;
        while (pos > 0 && (gain > gains[pos - 1] || (gain == gains[pos - 1] && v < candidates[pos - 1]))) {
            gains[pos] = gains[pos - 1]; candidates[pos] = candidates[pos - 1]; pos -= 1;
        }
        gains[pos] = gain; candidates[pos] = v; count += 1;
    }
    for (usz i = 0; i < count; i += 1) {
        usz v = candidates[i];
        best = search_mds(closed, n, full, covered | closed[v], chosen + 1, best);
    }
    return best;
}

fn long minimum_dominating_set_branch_bound(long* packed, usz length)
        @export("minimum_dominating_set_branch_bound") {
    if (packed == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = packed[0], m_value = packed[1];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    long max_edges = n_value * (n_value - 1) / 2;
    if (m_value < 0 || m_value > max_edges || length != 2 + 2 * (usz)m_value) return -1;
    usz n = (usz)n_value;
    ulong[MAX_N] adjacency = zeroed;
    for (usz edge = 0; edge < (usz)m_value; edge += 1) {
        long u_value = packed[2 + 2 * edge], v_value = packed[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        ulong bit = 1ul << v;
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit; adjacency[v] |= 1ul << u;
    }
    ulong[MAX_N] closed = zeroed;
    for (usz v = 0; v < n; v += 1) closed[v] = adjacency[v] | (1ul << v);
    ulong full = (1ul << n) - 1ul;
    ulong covered = 0;
    long greedy = 0;
    while (covered != full) {
        usz vertex = 0;
        long best_gain = -1;
        for (usz v = 0; v < n; v += 1) {
            long gain = popcount(closed[v] & ~covered);
            if (gain > best_gain) { vertex = v; best_gain = gain; }
        }
        covered |= closed[vertex]; greedy += 1;
    }
    return search_mds(&closed[0], n, full, 0, 0, greedy);
}
