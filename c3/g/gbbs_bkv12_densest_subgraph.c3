// Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt.
module gbbs_bkv12_densest_subgraph;
const usz N = 16;
const usz M = 64;
const double INVALID = -1e300;

fn double gbbs_bkv12_densest_subgraph(long* input, usz length) @export("gbbs_bkv12_densest_subgraph") {
    if (input == null || length < 2 || length > 132) return INVALID;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != 2 + 2 * (usz)m64) return INVALID;
    usz n = (usz)n64, m = (usz)m64;
    bool[N * N] adjacent = zeroed;
    long[N] degree = zeroed;
    usz[M] edge_u = zeroed, edge_v = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * N + v]) return INVALID;
        adjacent[u * N + v] = true; adjacent[v * N + u] = true;
        degree[u] += 1; degree[v] += 1; edge_u[edge] = u; edge_v[edge] = v;
    }
    bool[N] alive = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) alive[vertex] = true;
    usz remaining = n;
    double best = 0.0;
    while (remaining > 0) {
        long total = 0;
        for (usz vertex = 0; vertex < n; vertex += 1) if (alive[vertex]) total += degree[vertex];
        double density = (double)total / (double)remaining;
        if (density > best) best = density;
        bool[N] removed = zeroed;
        usz count = 0;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if (alive[vertex] && 1000 * degree[vertex] * (long)remaining <= 1001 * total) {
                removed[vertex] = true; count += 1;
            }
        }
        if (count == 0) return INVALID;
        for (usz vertex = 0; vertex < n; vertex += 1) if (removed[vertex]) alive[vertex] = false;
        remaining -= count;
        for (usz edge = 0; edge < m; edge += 1) {
            usz u = edge_u[edge], v = edge_v[edge];
            if (removed[u] && alive[v]) degree[v] -= 1;
            if (removed[v] && alive[u]) degree[u] -= 1;
        }
    }
    return best;
}
