#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 16
#define MAX_EDGES 64
#define MAX_RESOURCE 32
#define INF INT64_MAX

int64_t constrained_shortest_path(const int64_t *input, size_t length) {
    if (input == NULL || length < 5) return -2;
    const int64_t n_raw = input[0], m_raw = input[1];
    const int64_t start = input[2], target = input[3], limit_raw = input[4];
    if (n_raw < 1 || n_raw > MAX_NODES || m_raw < 0 || m_raw > MAX_EDGES ||
        limit_raw < 0 || limit_raw > MAX_RESOURCE) return -2;
    const size_t n = (size_t)n_raw, m = (size_t)m_raw, limit = (size_t)limit_raw;
    if (length != 5 + 4 * m || start < 0 || start >= n_raw || target < 0 || target >= n_raw) return -2;
    for (size_t e = 0; e < m; ++e) {
        const size_t p = 5 + 4 * e;
        if (input[p] < 0 || input[p] >= n_raw || input[p + 1] < 0 || input[p + 1] >= n_raw ||
            input[p + 2] < 0 || input[p + 2] > 1000 || input[p + 3] < 1 || input[p + 3] > MAX_RESOURCE) return -2;
    }
    int64_t dp[MAX_RESOURCE + 1][MAX_NODES];
    for (size_t r = 0; r <= limit; ++r)
        for (size_t u = 0; u < n; ++u) dp[r][u] = INF;
    dp[0][(size_t)start] = 0;
    for (size_t r = 0; r <= limit; ++r) {
        for (size_t u = 0; u < n; ++u) {
            if (dp[r][u] == INF) continue;
            for (size_t e = 0; e < m; ++e) {
                const size_t p = 5 + 4 * e;
                if ((size_t)input[p] != u) continue;
                const size_t resource = (size_t)input[p + 3];
                if (r + resource <= limit) {
                    const size_t v = (size_t)input[p + 1];
                    const int64_t candidate = dp[r][u] + input[p + 2];
                    if (candidate < dp[r + resource][v]) dp[r + resource][v] = candidate;
                }
            }
        }
    }
    int64_t answer = INF;
    for (size_t r = 0; r <= limit; ++r)
        if (dp[r][(size_t)target] < answer) answer = dp[r][(size_t)target];
    return answer == INF ? -1 : answer;
}
