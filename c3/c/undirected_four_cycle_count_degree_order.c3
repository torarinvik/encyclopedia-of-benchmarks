module undirected_four_cycle_count_degree_order;

const long MAX_N = 16;
const long MAX_M = 64;

// Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
fn long undirected_four_cycle_count_degree_order(long* input, usz length)
        @export("undirected_four_cycle_count_degree_order") {
    if (input == null || length < 2 || length > 131) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > MAX_M) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    if (length != 2 + 2 * m) return -1;

    usz[256] neighbors;
    usz[16] degree;
    for (usz q = 0; q < 256; q++) neighbors[q] = 0;
    for (usz q = 0; q < 16; q++) degree[q] = 0;
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
        neighbors[u * MAX_N + degree[u]] = v;
        degree[u]++;
        neighbors[v * MAX_N + degree[v]] = u;
        degree[v]++;
    }

    usz[16] order;
    usz[16] rank;
    for (usz i = 0; i < 16; i++) { order[i] = 0; rank[i] = 0; }
    for (usz i = 0; i < n; i++) order[i] = i;
    for (usz i = 1; i < n; i++) {
        usz key = order[i];
        usz j = i;
        while (j > 0) {
            usz prior = order[j - 1];
            if (degree[prior] < degree[key] || (degree[prior] == degree[key] && prior < key)) break;
            order[j] = prior;
            j--;
        }
        order[j] = key;
    }
    for (usz i = 0; i < n; i++) rank[order[i]] = i;

    long[16] count;
    for (usz i = 0; i < 16; i++) count[i] = 0;
    long total = 0;
    for (usz position = 0; position < n; position++) {
        usz pivot = order[position];
        for (usz bi = 0; bi < degree[pivot]; bi++) {
            usz middle = neighbors[pivot * MAX_N + bi];
            if (rank[middle] >= position) continue;
            for (usz ci = 0; ci < degree[middle]; ci++) {
                usz opposite = neighbors[middle * MAX_N + ci];
                if (rank[opposite] < position) {
                    total += count[opposite];
                    count[opposite]++;
                }
            }
        }
        for (usz vertex = 0; vertex < n; vertex++) count[vertex] = 0;
    }
    return total;
}
