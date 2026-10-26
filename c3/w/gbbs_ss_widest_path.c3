module gbbs_ss_widest_path;

const long MAX_N = 16;
const long MAX_M = 64;
const long MAX_INPUT = 195;
const long SOURCE_INFINITY = 2147483647;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded GBBS widest-path profile; see package LICENSE.txt.
long gbbs_ss_widest_path(long* input, usz length, char* output, usz capacity)
        @export("gbbs_ss_widest_path") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], source64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || source64 < 0 ||
        source64 >= n64 || length != 3 + 3 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64, source = (usz)source64;
    usz[MAX_M] edge_from;
    usz[MAX_M] edge_to;
    long[MAX_M] edge_capacity;
    for (usz edge = 0; edge < m; edge += 1) {
        long from = input[3 + 3 * edge], to = input[4 + 3 * edge], edge_width = input[5 + 3 * edge];
        if (from < 0 || from >= n64 || to < 0 || to >= n64 || edge_width < 1 || edge_width > 32) return -1;
        edge_from[edge] = (usz)from;
        edge_to[edge] = (usz)to;
        edge_capacity[edge] = edge_width;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N] width = zeroed;
    bool[MAX_N] settled = zeroed;
    width[source] = SOURCE_INFINITY;
    for (usz step = 0; step < n; step += 1) {
        usz u = n;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if (!settled[vertex] && (u == n || width[vertex] > width[u])) u = vertex;
        }
        if (u == n || width[u] == 0) break;
        settled[u] = true;
        for (usz edge = 0; edge < m; edge += 1) {
            if (edge_from[edge] != u) continue;
            usz v = edge_to[edge];
            if (settled[v]) continue;
            long candidate = width[u] < edge_capacity[edge] ? width[u] : edge_capacity[edge];
            if (candidate > width[v]) width[v] = candidate;
        }
    }
    for (usz vertex = 0; vertex < n; vertex += 1) store_i64_le(output, 8 * vertex, width[vertex]);
    return (long)output_bytes;
}
