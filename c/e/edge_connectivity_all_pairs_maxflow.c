#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 10, MAX_EDGES = 45, MAX_PARSEABLE = 93 };

static int pair_flow(const uint8_t adjacency[MAX_VERTICES][MAX_VERTICES],
                     size_t n, size_t source, size_t sink, int limit)
{
    int residual[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t u = 0; u < n; ++u)
        for (size_t v = 0; v < n; ++v)
            residual[u][v] = adjacency[u][v];

    int flow = 0;
    while (flow < limit) {
        int parent[MAX_VERTICES];
        size_t queue[MAX_VERTICES];
        for (size_t v = 0; v < n; ++v) parent[v] = -1;
        parent[source] = (int)source;
        size_t head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            const size_t u = queue[head++];
            for (size_t v = 0; v < n; ++v) {
                if (parent[v] < 0 && residual[u][v] > 0) {
                    parent[v] = (int)u;
                    queue[tail++] = v;
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
            residual[u][v] -= amount;
            residual[v][u] += amount;
        }
        flow += amount;
    }
    return flow;
}

int64_t edge_connectivity_all_pairs_maxflow(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 2 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;

    uint8_t adjacency[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t e = 0; e < m; ++e) {
        const int64_t left = input[2 + 2 * e], right = input[3 + 2 * e];
        if (left < 0 || right < 0 || left >= (int64_t)n || right >= (int64_t)n || left == right) return -1;
        const size_t u = (size_t)left, v = (size_t)right;
        if (adjacency[u][v] != 0) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }

    int best = (int)n - 1;
    for (size_t source = 0; source < n; ++source) {
        for (size_t sink = source + 1; sink < n; ++sink) {
            const int flow = pair_flow(adjacency, n, source, sink, best);
            if (flow < best) best = flow;
            if (best == 0) return 0;
        }
    }
    return best;
}
