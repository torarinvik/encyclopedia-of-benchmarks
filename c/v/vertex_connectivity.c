/* Clean-room vertex-split max-flow for undirected global vertex connectivity. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 10, MAX_M = 45, MAX_INPUT = 92, MAX_DN = 20 };

static int pair_vertex_flow(const uint64_t adjacency[MAX_N], size_t n,
                            size_t source_vertex, size_t target_vertex, int limit) {
    int residual[MAX_DN][MAX_DN] = {{0}};
    const size_t nodes = 2 * n;
    for (size_t v = 0; v < n; ++v)
        residual[2*v][2*v+1] = (v == source_vertex || v == target_vertex) ? (int)n : 1;
    for (size_t u = 0; u < n; ++u) {
        for (size_t v = u + 1; v < n; ++v) {
            if ((adjacency[u] & (UINT64_C(1) << v)) != 0) {
                residual[2*u+1][2*v] = 1;
                residual[2*v+1][2*u] = 1;
            }
        }
    }
    const size_t source = 2*source_vertex + 1, sink = 2*target_vertex;
    int flow = 0;
    while (flow < limit) {
        int parent[MAX_DN]; size_t queue[MAX_DN];
        for (size_t v = 0; v < nodes; ++v) parent[v] = -1;
        parent[source] = (int)source;
        size_t head = 0, tail = 0; queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            const size_t u = queue[head++];
            for (size_t v = 0; v < nodes; ++v) {
                if (parent[v] < 0 && residual[u][v] > 0) {
                    parent[v] = (int)u; queue[tail++] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) break;
        int amount = limit - flow;
        for (size_t v = sink; v != source; v = (size_t)parent[v]) {
            const size_t u = (size_t)parent[v];
            if (residual[u][v] < amount) amount = residual[u][v];
        }
        for (size_t v = sink; v != source; v = (size_t)parent[v]) {
            const size_t u = (size_t)parent[v];
            residual[u][v] -= amount; residual[v][u] += amount;
        }
        flow += amount;
    }
    return flow;
}

int64_t vertex_connectivity(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2*m) return -1;
    uint64_t adjacency[MAX_N] = {0};
    for (size_t e = 0; e < m; ++e) {
        const int64_t left = input[2+2*e], right = input[3+2*e];
        if (left < 0 || right < 0 || left >= (int64_t)n || right >= (int64_t)n) return -1;
        if (left != right) {
            adjacency[(size_t)left] |= UINT64_C(1) << (size_t)right;
            adjacency[(size_t)right] |= UINT64_C(1) << (size_t)left;
        }
    }
    if (n <= 1) return 0;
    uint64_t reached = UINT64_C(1); size_t queue[MAX_N], head = 0, tail = 0;
    queue[tail++] = 0;
    while (head < tail) {
        const size_t u = queue[head++];
        for (size_t v = 0; v < n; ++v) {
            const uint64_t bit = UINT64_C(1) << v;
            if ((adjacency[u] & bit) != 0 && (reached & bit) == 0) {
                reached |= bit; queue[tail++] = v;
            }
        }
    }
    if (reached != ((UINT64_C(1) << n) - 1)) return 0;
    int best = (int)n - 1;
    for (size_t source = 0; source < n; ++source) {
        for (size_t target = source + 1; target < n; ++target) {
            if ((adjacency[source] & (UINT64_C(1) << target)) != 0) continue;
            const int flow = pair_vertex_flow(adjacency, n, source, target, best);
            if (flow < best) best = flow;
            if (best == 0) return 0;
        }
    }
    return best;
}
