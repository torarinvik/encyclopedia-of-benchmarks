module deterministic_linear_threshold_spread;

const usz MAX_N = 8;
const usz MAX_M = 24;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long deterministic_linear_threshold_spread(long* input, usz length, char* output,
        usz capacity) @export("deterministic_linear_threshold_spread") {
    if (input == null || length < 3 || length > 92) return -1;
    long n_value = input[0], m_value = input[1], s_value = input[2];
    if (n_value < 1 || n_value > 8 || m_value < 0 || m_value > 24 || s_value < 0 || s_value > n_value) return -1;
    usz n = (usz)n_value, m = (usz)m_value, seed_count = (usz)s_value;
    usz edge_offset = 3 + seed_count, threshold_offset = edge_offset + 3 * m;
    if (length != threshold_offset + n) return -1;
    bool[MAX_N] seeded = {};
    bool[MAX_N][MAX_N] seen = {};
    long[MAX_N] head = {};
    long[MAX_M] edge_to = {}, edge_weight = {}, edge_next = {};
    long[MAX_N] incoming = {}, threshold = {}, activation_round = {}, accumulated = {};
    for (usz v = 0; v < n; v++) head[v] = -1;
    for (usz i = 0; i < seed_count; i++) {
        long seed = input[3 + i];
        if (seed < 0 || (ulong)seed >= n || seeded[(usz)seed]) return -1;
        seeded[(usz)seed] = true;
    }
    for (usz i = 0; i < m; i++) {
        long u = input[edge_offset + 3 * i], v = input[edge_offset + 3 * i + 1], w = input[edge_offset + 3 * i + 2];
        if (u < 0 || (ulong)u >= n || v < 0 || (ulong)v >= n || u == v || w < 0 || w > 16 || seen[(usz)u][(usz)v]) return -1;
        seen[(usz)u][(usz)v] = true;
        incoming[(usz)v] += w;
        if (incoming[(usz)v] > 16) return -1;
        edge_to[i] = v; edge_weight[i] = w; edge_next[i] = head[(usz)u]; head[(usz)u] = (long)i;
    }
    for (usz v = 0; v < n; v++) {
        threshold[v] = input[threshold_offset + v];
        if (threshold[v] < 1 || threshold[v] > 16) return -1;
        activation_round[v] = seeded[v] ? 0 : -1;
    }
    usz output_bytes = 8 * (n + 2);
    if (output == null || capacity < output_bytes) return -2;
    usz[MAX_N] frontier = {}, following = {};
    usz frontier_count = 0;
    for (usz v = 0; v < n; v++) if (seeded[v]) frontier[frontier_count++] = v;
    long waves = 0;
    while (frontier_count != 0) {
        usz following_count = 0;
        for (usz i = 0; i < frontier_count; i++) {
            usz source = frontier[i];
            for (long e = head[source]; e >= 0; e = edge_next[(usz)e]) {
                usz target = (usz)edge_to[(usz)e];
                if (activation_round[target] >= 0) continue;
                accumulated[target] += edge_weight[(usz)e];
                if (accumulated[target] >= threshold[target]) {
                    activation_round[target] = waves + 1;
                    following[following_count++] = target;
                }
            }
        }
        frontier_count = following_count;
        for (usz i = 0; i < following_count; i++) frontier[i] = following[i];
        if (following_count != 0) waves++;
    }
    store_i64_le(output, 0, n_value); store_i64_le(output, 8, waves);
    for (usz v = 0; v < n; v++) store_i64_le(output, 8 * (v + 2), activation_round[v]);
    return (long)output_bytes;
}
