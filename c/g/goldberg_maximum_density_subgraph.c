/* Clean-room Goldberg exact maximum-density profile. */
#include <stddef.h>
#include <stdint.h>

static int64_t gcd_i64(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}

int64_t goldberg_maximum_density_subgraph(const int64_t *input, size_t length) {
    enum { MAX_N = 8, MAX_M = 28, MAX_PARSEABLE = 59, MAX_NETWORK = 10 };
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int64_t degree[MAX_N] = {0};
    for (int e = 0; e < m; ++e) {
        const int64_t u64 = input[2 + 2 * (size_t)e];
        const int64_t v64 = input[3 + 2 * (size_t)e];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const int u = (int)u64, v = (int)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++degree[u]; ++degree[v];
    }
    if (m == 0) return 1;

    int64_t low = 0, high = m, denominator = 1;
    uint16_t best_mask = 0;
    while ((high - low) * n * (n - 1) >= denominator) {
        const int64_t low2 = 2 * low, high2 = 2 * high;
        const int64_t midpoint = low + high, next_denominator = 2 * denominator;
        const int source = n, sink = n + 1, network_size = n + 2;
        int64_t residual[MAX_NETWORK][MAX_NETWORK] = {{0}};
        for (int v = 0; v < n; ++v) {
            const int64_t source_capacity = (int64_t)m * next_denominator;
            residual[source][v] = source_capacity;
            residual[v][sink] = source_capacity + 2 * midpoint - next_denominator * degree[v];
        }
        for (int e = 0; e < m; ++e) {
            const int u = (int)input[2 + 2 * (size_t)e];
            const int v = (int)input[3 + 2 * (size_t)e];
            residual[u][v] += next_denominator;
            residual[v][u] += next_denominator;
        }
        for (;;) {
            int parent[MAX_NETWORK];
            for (int v = 0; v < network_size; ++v) parent[v] = -1;
            int queue[MAX_NETWORK], head = 0, tail = 0;
            parent[source] = source; queue[tail++] = source;
            while (head < tail && parent[sink] == -1) {
                const int here = queue[head++];
                for (int there = 0; there < network_size; ++there) {
                    if (parent[there] == -1 && residual[here][there] > 0) {
                        parent[there] = here; queue[tail++] = there;
                        if (there == sink) break;
                    }
                }
            }
            if (parent[sink] == -1) break;
            int64_t amount = INT64_MAX;
            for (int v = sink; v != source; v = parent[v])
                if (residual[parent[v]][v] < amount) amount = residual[parent[v]][v];
            for (int v = sink; v != source; v = parent[v]) {
                residual[parent[v]][v] -= amount;
                residual[v][parent[v]] += amount;
            }
        }
        uint8_t reachable[MAX_NETWORK] = {0};
        int queue[MAX_NETWORK], head = 0, tail = 0;
        reachable[source] = 1; queue[tail++] = source;
        while (head < tail) {
            const int here = queue[head++];
            for (int there = 0; there < network_size; ++there) {
                if (!reachable[there] && residual[here][there] > 0) {
                    reachable[there] = 1; queue[tail++] = there;
                }
            }
        }
        uint16_t selected = 0;
        for (int v = 0; v < n; ++v) if (reachable[v]) selected |= (uint16_t)(1u << v);
        if (selected != 0) { low = midpoint; high = high2; best_mask = selected; }
        else { low = low2; high = midpoint; }
        denominator = next_denominator;
    }
    int64_t vertex_count = 0, edge_count = 0;
    for (int v = 0; v < n; ++v) if (best_mask & (uint16_t)(1u << v)) ++vertex_count;
    if (vertex_count == 0) return 1;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v)
        if ((best_mask & (uint16_t)(1u << u)) && (best_mask & (uint16_t)(1u << v)) && adjacent[u][v]) ++edge_count;
    const int64_t divisor = gcd_i64(edge_count, vertex_count);
    return (edge_count / divisor) * (n + 1) + vertex_count / divisor;
}
