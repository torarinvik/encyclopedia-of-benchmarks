module shortest_path_visiting_all_nodes;
const usz MAX_N = 10;
const usz MAX_STATES = 10240;
const usz MAX_PARSEABLE_LENGTH = 93;

fn long shortest_path_visiting_all_nodes(long* input, usz length) @export("shortest_path_visiting_all_nodes") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > 10 || m_value < 0 || m_value > 45) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    if (m > n * (n - 1) / 2 || length != 2 + 2 * m) return -1;

    ulong[MAX_N] adjacency = zeroed;
    for (usz edge = 0; edge < m; edge++) {
        long u_value = input[2 + 2 * edge];
        long v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        ulong u_bit = 1UL << v;
        ulong v_bit = 1UL << u;
        if ((adjacency[u] & u_bit) != 0) return -1;
        adjacency[u] |= u_bit;
        adjacency[v] |= v_bit;
    }

    ulong reached = 1UL;
    for (;;) {
        ulong previous = reached;
        for (usz vertex = 0; vertex < n; vertex++)
            if ((reached & (1UL << vertex)) != 0) reached |= adjacency[vertex];
        if (reached == previous) break;
    }
    ulong full_graph = (1UL << n) - 1UL;
    if (reached != full_graph) return -1;

    usz full = ((usz)1 << n) - 1;
    usz state_count = ((usz)1 << n) * n;
    long[MAX_STATES] distance;
    usz[MAX_STATES] queue;
    for (usz i = 0; i < state_count; i++) distance[i] = -1;
    usz head = 0;
    usz tail = 0;
    for (usz start = 0; start < n; start++) {
        usz state = ((usz)1 << start) * n + start;
        distance[state] = 0;
        queue[tail++] = state;
    }
    while (head < tail) {
        usz state = queue[head++];
        usz mask = state / n;
        usz vertex = state % n;
        if (mask == full) return distance[state];
        for (usz next = 0; next < n; next++) {
            if ((adjacency[vertex] & (1UL << next)) == 0) continue;
            usz next_mask = mask | ((usz)1 << next);
            usz next_state = next_mask * n + next;
            if (distance[next_state] >= 0) continue;
            distance[next_state] = distance[state] + 1;
            queue[tail++] = next_state;
        }
    }
    return -1;
}
