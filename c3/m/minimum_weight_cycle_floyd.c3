module minimum_weight_cycle_floyd;

const usz MAX_N = 9;
const usz MAX_CELLS = 81;
const usz MAX_INPUT_LENGTH = 111;
const long INF = 1152921504606846976;

fn void store_i64_le(char *output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long minimum_weight_cycle_floyd(long *input, usz length, char *output,
        usz capacity) @export("minimum_weight_cycle_floyd") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 3 || n_value > 9 || m_value < 0
            || m_value > n_value * (n_value - 1) / 2) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 3 * m) return -1;

    long[MAX_CELLS] edge = zeroed;
    long[MAX_CELLS] dist = zeroed;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) edge[i * MAX_N + j] = i == j ? 0 : INF;
    }
    for (usz e = 0; e < m; e++) {
        usz offset = 2 + 3 * e;
        long u_value = input[offset], v_value = input[offset + 1], weight = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
                || u_value == v_value || weight < 1 || weight > 1000) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        if (edge[u * MAX_N + v] != INF) return -1;
        edge[u * MAX_N + v] = weight;
        edge[v * MAX_N + u] = weight;
    }
    if (output == null || capacity < 8) return -2;
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++) dist[i * MAX_N + j] = edge[i * MAX_N + j];

    long best = INF;
    for (usz k = 0; k < n; k++) {
        for (usz i = 0; i < k; i++) {
            if (edge[i * MAX_N + k] == INF) continue;
            for (usz j = i + 1; j < k; j++) {
                if (edge[k * MAX_N + j] == INF || dist[i * MAX_N + j] == INF) continue;
                long candidate = edge[i * MAX_N + k] + edge[k * MAX_N + j]
                    + dist[i * MAX_N + j];
                if (candidate < best) best = candidate;
            }
        }
        for (usz i = 0; i < n; i++) {
            if (dist[i * MAX_N + k] == INF) continue;
            for (usz j = 0; j < n; j++) {
                if (dist[k * MAX_N + j] == INF) continue;
                long candidate = dist[i * MAX_N + k] + dist[k * MAX_N + j];
                if (candidate < dist[i * MAX_N + j]) dist[i * MAX_N + j] = candidate;
            }
        }
    }
    store_i64_le(output, best == INF ? -1 : best);
    return 8;
}
