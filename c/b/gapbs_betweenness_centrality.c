/* Clean-room bounded Brandes profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 74 };

int64_t gapbs_betweenness_centrality(const int64_t *input, size_t length) {
    if (input == NULL || length < 12 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], k64 = input[1];
    if (n64 < 3 || n64 > MAX_N || k64 < 1 || k64 > n64) return -1;
    const size_t n = (size_t)n64, k = (size_t)k64;
    if (length != 2 + k + n * n) return -1;
    int sources[MAX_N];
    for (size_t i = 0; i < k; ++i) {
        const int64_t source = input[2 + i];
        if (source < 0 || source >= n64) return -1;
        for (size_t j = 0; j < i; ++j) if (sources[j] == source) return -1;
        sources[i] = (int)source;
    }
    int adjacency[MAX_N][MAX_N] = {{0}};
    for (size_t u = 0; u < n; ++u) {
        for (size_t v = 0; v < n; ++v) {
            const int64_t edge = input[2 + k + u * n + v];
            if ((edge != 0 && edge != 1) || (u == v && edge != 0)) return -1;
            adjacency[u][v] = (int)edge;
        }
    }
    for (size_t u = 0; u < n; ++u)
        for (size_t v = u + 1; v < n; ++v)
            if (adjacency[u][v] != adjacency[v][u]) return -1;

    float scores[MAX_N] = {0};
    for (size_t si = 0; si < k; ++si) {
        int depth[MAX_N];
        int queue[MAX_N];
        double paths[MAX_N] = {0};
        float delta[MAX_N] = {0};
        for (size_t v = 0; v < n; ++v) depth[v] = -1;
        const int source = sources[si];
        depth[source] = 0; paths[source] = 1.0;
        size_t head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail) {
            const int u = queue[head++];
            for (size_t v = 0; v < n; ++v) if (adjacency[u][v]) {
                if (depth[v] == -1) { depth[v] = depth[u] + 1; queue[tail++] = (int)v; }
                if (depth[v] == depth[u] + 1) paths[v] += paths[u];
            }
        }
        int max_depth = 0;
        for (size_t v = 0; v < n; ++v) if (depth[v] > max_depth) max_depth = depth[v];
        for (int d = max_depth; d >= 0; --d) {
            for (size_t u = 0; u < n; ++u) if (depth[u] == d) {
                float delta_u = 0.0f;
                for (size_t v = 0; v < n; ++v) if (adjacency[u][v] && depth[v] == d + 1) {
                    const float one_plus = 1.0f + delta[v];
                    const double contribution = (paths[u] / paths[v]) * (double)one_plus;
                    delta_u = (float)((double)delta_u + contribution);
                }
                delta[u] = delta_u;
                scores[u] = (float)((double)scores[u] + (double)delta_u);
            }
        }
    }
    float biggest = 0.0f;
    for (size_t v = 0; v < n; ++v) if (scores[v] > biggest) biggest = scores[v];
    if (!(biggest > 0.0f)) return -1;
    int64_t checksum = 0;
    for (size_t v = 0; v < n; ++v) {
        const float normalized = scores[v] / biggest;
        const int64_t qscore = (int64_t)((double)normalized * 1000.0 + 0.5);
        checksum += (int64_t)(v + 1) * qscore;
    }
    return checksum;
}
