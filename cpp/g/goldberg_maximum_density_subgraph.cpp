// Clean-room Goldberg exact maximum-density profile.
#include <cstddef>
#include <cstdint>
#include <algorithm>
#include <limits>

extern "C" std::int64_t goldberg_maximum_density_subgraph(const std::int64_t *input, std::size_t length) {
    constexpr int MAX_N = 8, MAX_M = 28, MAX_NETWORK = 10;
    if (input == nullptr || length < 2 || length > 59) return -1;
    const std::int64_t n64 = input[0], m64 = input[1];
    if (n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    bool adjacent[MAX_N][MAX_N]{};
    std::int64_t degree[MAX_N]{};
    for (int e = 0; e < m; ++e) {
        const auto u64 = input[2 + 2 * static_cast<std::size_t>(e)];
        const auto v64 = input[3 + 2 * static_cast<std::size_t>(e)];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        ++degree[u]; ++degree[v];
    }
    if (m == 0) return 1;
    std::int64_t low = 0, high = m, denominator = 1;
    bool best[MAX_N]{};
    while ((high - low) * n * (n - 1) >= denominator) {
        const auto low2 = 2 * low, high2 = 2 * high;
        const auto midpoint = low + high, next_denominator = 2 * denominator;
        const int source = n, sink = n + 1, network_size = n + 2;
        std::int64_t residual[MAX_NETWORK][MAX_NETWORK]{};
        for (int v = 0; v < n; ++v) {
            const auto source_capacity = static_cast<std::int64_t>(m) * next_denominator;
            residual[source][v] = source_capacity;
            residual[v][sink] = source_capacity + 2 * midpoint - next_denominator * degree[v];
        }
        for (int e = 0; e < m; ++e) {
            const int u = static_cast<int>(input[2 + 2 * static_cast<std::size_t>(e)]);
            const int v = static_cast<int>(input[3 + 2 * static_cast<std::size_t>(e)]);
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
            std::int64_t amount = std::numeric_limits<std::int64_t>::max();
            for (int v = sink; v != source; v = parent[v]) amount = std::min(amount, residual[parent[v]][v]);
            for (int v = sink; v != source; v = parent[v]) {
                residual[parent[v]][v] -= amount;
                residual[v][parent[v]] += amount;
            }
        }
        bool reachable[MAX_NETWORK]{};
        int queue[MAX_NETWORK], head = 0, tail = 0;
        reachable[source] = true; queue[tail++] = source;
        while (head < tail) {
            const int here = queue[head++];
            for (int there = 0; there < network_size; ++there) {
                if (!reachable[there] && residual[here][there] > 0) {
                    reachable[there] = true; queue[tail++] = there;
                }
            }
        }
        bool selected[MAX_N]{};
        bool any = false;
        for (int v = 0; v < n; ++v) { selected[v] = reachable[v]; any = any || selected[v]; }
        if (any) { for (int v = 0; v < n; ++v) best[v] = selected[v]; low = midpoint; high = high2; }
        else { low = low2; high = midpoint; }
        denominator = next_denominator;
    }
    std::int64_t vertex_count = 0, edge_count = 0;
    for (int v = 0; v < n; ++v) if (best[v]) ++vertex_count;
    if (vertex_count == 0) return 1;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v)
        if (best[u] && best[v] && adjacent[u][v]) ++edge_count;
    std::int64_t a = edge_count, b = vertex_count;
    while (b != 0) { const auto r = a % b; a = b; b = r; }
    return (edge_count / a) * (n + 1) + vertex_count / a;
}
