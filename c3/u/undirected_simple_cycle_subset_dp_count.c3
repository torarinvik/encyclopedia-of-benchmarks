module undirected_simple_cycle_subset_dp_count;

const long MAX_N = 14;
const long MAX_M = 91;
const usz MAX_STATES = 1 << 14;

// Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
fn long undirected_simple_cycle_subset_dp_count(long* input, usz length)
        @export("undirected_simple_cycle_subset_dp_count") {
    if (input == null || length < 2 || length > 185) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 ||
        m_value > n_value * (n_value - 1) / 2 || m_value > MAX_M) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    if (length != 2 + 2 * m) return -1;

    char[196] adjacency;
    usz[196] neighbors;
    usz[14] degree;
    for (usz i = 0; i < 196; i++) { adjacency[i] = 0; neighbors[i] = 0; }
    for (usz i = 0; i < 14; i++) degree[i] = 0;
    long previous_u = -1;
    long previous_v = -1;
    for (usz edge = 0; edge < m; edge++) {
        long u_value = input[2 + 2 * edge];
        long v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value >= v_value)
            return -1;
        if (edge != 0 && (u_value < previous_u || (u_value == previous_u && v_value <= previous_v)))
            return -1;
        previous_u = u_value;
        previous_v = v_value;
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        adjacency[u * MAX_N + v] = 1;
        adjacency[v * MAX_N + u] = 1;
        neighbors[u * MAX_N + degree[u]] = v;
        degree[u]++;
        neighbors[v * MAX_N + degree[v]] = u;
        degree[v]++;
    }

    long[MAX_STATES * 14] dp = zeroed;
    usz state_count = (usz)1 << n;
    for (usz start = 0; start < n; start++) dp[((usz)1 << start) * MAX_N + start] = 1;
    long oriented_cycles = 0;
    for (usz mask = 1; mask < state_count; mask++) {
        usz start = 0;
        while ((mask & ((usz)1 << start)) == 0) start++;
        usz cardinality = 0;
        for (usz vertex = 0; vertex < n; vertex++)
            if ((mask & ((usz)1 << vertex)) != 0) cardinality++;
        for (usz endpoint = 0; endpoint < n; endpoint++) {
            if ((mask & ((usz)1 << endpoint)) == 0) continue;
            long ways = dp[mask * MAX_N + endpoint];
            if (ways == 0) continue;
            if (cardinality >= 3 && adjacency[endpoint * MAX_N + start] != 0) oriented_cycles += ways;
            for (usz i = 0; i < degree[endpoint]; i++) {
                usz next = neighbors[endpoint * MAX_N + i];
                if (next > start && (mask & ((usz)1 << next)) == 0)
                    dp[(mask | ((usz)1 << next)) * MAX_N + next] += ways;
            }
        }
    }
    return oriented_cycles / 2;
}
