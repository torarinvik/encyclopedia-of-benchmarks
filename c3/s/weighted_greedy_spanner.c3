module weighted_greedy_spanner;

const usz MAX_N = 8;
const usz MAX_M = 28;
const usz MAX_INPUT = 88;

long weighted_greedy_spanner(long* input, usz length, char* output, usz capacity)
        @export("weighted_greedy_spanner") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], k = input[2];
    if (n64 < 2 || n64 > 8 || m64 < 0 || m64 > 28 || k < 1 || k > 3 ||
        length != 3 + 3 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    long[MAX_M] edge_u = zeroed, edge_v = zeroed, edge_w = zeroed;
    usz[MAX_M] order = zeroed;
    long[MAX_N * MAX_N] adjacency = zeroed;
    char[MAX_M] selected = zeroed;
    for (usz i = 0; i < m; i++) {
        edge_u[i] = input[3 + 3 * i];
        edge_v[i] = input[4 + 3 * i];
        edge_w[i] = input[5 + 3 * i];
        if (edge_u[i] < 0 || edge_v[i] <= edge_u[i] || edge_v[i] >= n64 || edge_w[i] < 1 || edge_w[i] > 32) return -1;
        for (usz j = 0; j < i; j++) if (edge_u[j] == edge_u[i] && edge_v[j] == edge_v[i]) return -1;
        order[i] = i;
    }
    for (usz i = 1; i < m; i++) {
        usz key = order[i], pos = i;
        while (pos > 0) {
            usz prev = order[pos - 1];
            if (edge_w[prev] < edge_w[key] || (edge_w[prev] == edge_w[key] && edge_u[prev] < edge_u[key]) ||
                (edge_w[prev] == edge_w[key] && edge_u[prev] == edge_u[key] && edge_v[prev] <= edge_v[key])) break;
            order[pos] = prev;
            pos--;
        }
        order[pos] = key;
    }
    if (output == null || capacity < m) return -2;
    for (usz rank = 0; rank < m; rank++) {
        usz edge = order[rank], source = (usz)edge_u[edge], target = (usz)edge_v[edge];
        long[MAX_N] distance = zeroed;
        bool[MAX_N] settled = zeroed;
        for (usz v = 0; v < n; v++) distance[v] = 1152921504606846976;
        distance[source] = 0;
        for (usz step = 0; step < n; step++) {
            usz vertex = n;
            for (usz v = 0; v < n; v++) if (!settled[v] && (vertex == n || distance[v] < distance[vertex])) vertex = v;
            if (vertex == n || distance[vertex] == 1152921504606846976) break;
            settled[vertex] = true;
            for (usz v = 0; v < n; v++) {
                long weight = adjacency[vertex * MAX_N + v];
                if (weight > 0 && distance[v] > distance[vertex] + weight) distance[v] = distance[vertex] + weight;
            }
        }
        if (distance[target] > (2 * k - 1) * edge_w[edge]) {
            selected[edge] = 1;
            adjacency[source * MAX_N + target] = edge_w[edge];
            adjacency[target * MAX_N + source] = edge_w[edge];
        }
    }
    for (usz i = 0; i < m; i++) output[i] = selected[i];
    return (long)m;
}
