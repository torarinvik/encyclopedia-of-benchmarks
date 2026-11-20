// Clean-room Goldberg exact maximum-density profile.
module goldberg_maximum_density_subgraph;
const usz MAX_N = 8;
const usz MAX_M = 28;
const usz MAX_NETWORK = 10;
const long INVALID_RESULT = -1;

fn long goldberg_maximum_density_subgraph(long* input, usz length) @export("goldberg_maximum_density_subgraph") {
    if (input == null || length < 2 || length > 59) return INVALID_RESULT;
    long n64 = input[0], m64 = input[1];
    if (n64 < 2 || n64 > 8 || m64 < 0 || m64 > 28 || length != 2 + 2 * (usz)m64) return INVALID_RESULT;
    usz n = (usz)n64, m = (usz)m64;
    uint8[MAX_N * MAX_N] adjacent = zeroed;
    long[MAX_N] degree = zeroed;
    for (usz e = 0; e < m; e += 1) {
        long u64 = input[2 + 2 * e], v64 = input[3 + 2 * e];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID_RESULT;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v] != 0) return INVALID_RESULT;
        adjacent[u * MAX_N + v] = 1; adjacent[v * MAX_N + u] = 1;
        degree[u] += 1; degree[v] += 1;
    }
    if (m == 0) return 1;
    long low = 0, high = (long)m, denominator = 1;
    bool[MAX_N] best = zeroed;
    while ((high - low) * (long)n * (long)(n - 1) >= denominator) {
        long low2 = 2 * low, high2 = 2 * high;
        long midpoint = low + high, next_denominator = 2 * denominator;
        usz source = n, sink = n + 1, network_size = n + 2;
        long[MAX_NETWORK * MAX_NETWORK] residual = zeroed;
        for (usz v = 0; v < n; v += 1) {
            long source_capacity = (long)m * next_denominator;
            residual[source * MAX_NETWORK + v] = source_capacity;
            residual[v * MAX_NETWORK + sink] = source_capacity + 2 * midpoint - next_denominator * degree[v];
        }
        for (usz e = 0; e < m; e += 1) {
            usz u = (usz)input[2 + 2 * e], v = (usz)input[3 + 2 * e];
            residual[u * MAX_NETWORK + v] += next_denominator;
            residual[v * MAX_NETWORK + u] += next_denominator;
        }
        while (true) {
            long[MAX_NETWORK] parent;
            for (usz v = 0; v < network_size; v += 1) parent[v] = -1;
            usz[MAX_NETWORK] queue;
            usz head = 0, tail = 0;
            parent[source] = (long)source; queue[tail] = source; tail += 1;
            while (head < tail && parent[sink] == -1) {
                usz here = queue[head]; head += 1;
                for (usz there = 0; there < network_size; there += 1) {
                    if (parent[there] == -1 && residual[here * MAX_NETWORK + there] > 0) {
                        parent[there] = (long)here; queue[tail] = there; tail += 1;
                        if (there == sink) break;
                    }
                }
            }
            if (parent[sink] == -1) break;
            long amount = 0x7fffffffffffffff;
            usz vertex = sink;
            while (vertex != source) {
                usz previous = (usz)parent[vertex];
                if (residual[previous * MAX_NETWORK + vertex] < amount) amount = residual[previous * MAX_NETWORK + vertex];
                vertex = previous;
            }
            vertex = sink;
            while (vertex != source) {
                usz previous = (usz)parent[vertex];
                residual[previous * MAX_NETWORK + vertex] -= amount;
                residual[vertex * MAX_NETWORK + previous] += amount;
                vertex = previous;
            }
        }
        bool[MAX_NETWORK] reachable = zeroed;
        usz[MAX_NETWORK] queue;
        usz head = 0, tail = 0;
        reachable[source] = true; queue[tail] = source; tail += 1;
        while (head < tail) {
            usz here = queue[head]; head += 1;
            for (usz there = 0; there < network_size; there += 1) {
                if (!reachable[there] && residual[here * MAX_NETWORK + there] > 0) {
                    reachable[there] = true; queue[tail] = there; tail += 1;
                }
            }
        }
        bool[MAX_N] selected = zeroed;
        bool any = false;
        for (usz v = 0; v < n; v += 1) { selected[v] = reachable[v]; if (selected[v]) any = true; }
        if (any) { for (usz v = 0; v < n; v += 1) best[v] = selected[v]; low = midpoint; high = high2; }
        else { low = low2; high = midpoint; }
        denominator = next_denominator;
    }
    long vertex_count = 0, edge_count = 0;
    for (usz v = 0; v < n; v += 1) if (best[v]) vertex_count += 1;
    if (vertex_count == 0) return 1;
    for (usz u = 0; u < n; u += 1) for (usz v = u + 1; v < n; v += 1)
        if (best[u] && best[v] && adjacent[u * MAX_N + v] != 0) edge_count += 1;
    long a = edge_count, b = vertex_count;
    while (b != 0) { long r = a % b; a = b; b = r; }
    return (edge_count / a) * ((long)n64 + 1) + vertex_count / a;
}
