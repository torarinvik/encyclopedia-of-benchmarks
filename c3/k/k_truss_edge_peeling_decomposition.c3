module k_truss_edge_peeling_decomposition;

const long MAX_N = 16;
const long MAX_M = 120;
const long MAX_PARSEABLE_INPUT = 243;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded edge-peeling truss decomposition.
fn long k_truss_edge_peeling_decomposition(long* input, usz length,
        char* output, usz capacity) @export("k_truss_edge_peeling_decomposition") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (usz)m64 || length > 242) return -1;
    usz n = (usz)n64, m = (usz)m64;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    int[MAX_N * MAX_N] edge_index;
    int[MAX_M] edge_u, edge_v, support;
    bool[MAX_M] alive = zeroed;
    long[MAX_M] trussness = zeroed;
    for (usz cell = 0; cell < MAX_N * MAX_N; cell += 1) edge_index[cell] = -1;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
        edge_index[u * MAX_N + v] = (int)edge;
        edge_index[v * MAX_N + u] = (int)edge;
        edge_u[edge] = (int)u;
        edge_v[edge] = (int)v;
        support[edge] = 0;
        alive[edge] = true;
    }
    for (usz u = 0; u < n; u += 1)
        for (usz v = u + 1; v < n; v += 1)
            for (usz w = v + 1; w < n; w += 1)
                if (adjacent[u * MAX_N + v] && adjacent[u * MAX_N + w] && adjacent[v * MAX_N + w]) {
                    support[(usz)edge_index[u * MAX_N + v]] += 1;
                    support[(usz)edge_index[u * MAX_N + w]] += 1;
                    support[(usz)edge_index[v * MAX_N + w]] += 1;
                }
    usz output_bytes = 8 * m;
    if (output == null || capacity < output_bytes) return -2;
    usz remaining = m;
    int level = 0;
    while (remaining > 0) {
        int selected = -1;
        for (usz edge = 0; edge < m; edge += 1)
            if (alive[edge] && (selected < 0 || support[edge] < support[(usz)selected])) selected = (int)edge;
        if (support[(usz)selected] > level) level = support[(usz)selected];
        trussness[(usz)selected] = (long)level + 2;
        alive[(usz)selected] = false;
        remaining -= 1;
        usz u = (usz)edge_u[(usz)selected], v = (usz)edge_v[(usz)selected];
        for (usz w = 0; w < n; w += 1) {
            if (w == u || w == v || !adjacent[u * MAX_N + w] || !adjacent[v * MAX_N + w]) continue;
            usz first = (usz)edge_index[u * MAX_N + w];
            usz second = (usz)edge_index[v * MAX_N + w];
            if (alive[first] && alive[second]) {
                if (support[first] > level) support[first] -= 1;
                if (support[second] > level) support[second] -= 1;
            }
        }
    }
    for (usz edge = 0; edge < m; edge += 1) store_i64_le(output, 8 * edge, trussness[edge]);
    return (long)output_bytes;
}
