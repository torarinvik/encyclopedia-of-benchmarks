#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 14, MAX_K = 5, MAX_INPUT = 50, MAX_MASKS = 1 << MAX_K };
static const int64_t INF = INT64_C(1000000000000000000);

int64_t steiner_tree_subset_dp(const int64_t *input, size_t length) {
    if (!input || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], m0 = input[1], k0 = input[2];
    if (n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > MAX_M || k0 < 1 || k0 > MAX_K || k0 > n0) return -1;
    const int n = (int)n0, m = (int)m0, k = (int)k0;
    if (m > n * (n - 1) / 2 || length != (size_t)(3 + k + 3 * m)) return -1;

    bool terminal_seen[MAX_N] = {false};
    int terminals[MAX_K];
    for (int i = 0; i < k; ++i) {
        const int64_t vertex = input[3 + i];
        if (vertex < 0 || vertex >= n || terminal_seen[vertex]) return -1;
        terminal_seen[vertex] = true;
        terminals[i] = (int)vertex;
    }

    bool present[MAX_N][MAX_N] = {{false}};
    int64_t weight[MAX_N][MAX_N] = {{0}};
    for (int i = 0; i < m; ++i) {
        const int64_t u0 = input[3 + k + 3 * i], v0 = input[4 + k + 3 * i], w = input[5 + k + 3 * i];
        if (u0 < 0 || u0 >= v0 || v0 >= n || w < 0 || w > 1000) return -1;
        const int u = (int)u0, v = (int)v0;
        if (present[u][v]) return -1;
        present[u][v] = present[v][u] = true;
        weight[u][v] = weight[v][u] = w;
    }

    int64_t dp[MAX_MASKS][MAX_N];
    for (int mask = 0; mask < MAX_MASKS; ++mask)
        for (int v = 0; v < MAX_N; ++v) dp[mask][v] = INF;
    for (int bit = 0; bit < k; ++bit) dp[1 << bit][terminals[bit]] = 0;

    const int masks = 1 << k;
    for (int mask = 1; mask < masks; ++mask) {
        if ((mask & (mask - 1)) != 0) {
            for (int sub = (mask - 1) & mask; sub != 0; sub = (sub - 1) & mask) {
                const int other = mask ^ sub;
                if (sub >= other) continue;
                for (int v = 0; v < n; ++v) {
                    if (dp[sub][v] < INF && dp[other][v] < INF) {
                        const int64_t candidate = dp[sub][v] + dp[other][v];
                        if (candidate < dp[mask][v]) dp[mask][v] = candidate;
                    }
                }
            }
        }

        bool used[MAX_N] = {false};
        for (int step = 0; step < n; ++step) {
            int chosen = -1;
            for (int v = 0; v < n; ++v)
                if (!used[v] && (chosen < 0 || dp[mask][v] < dp[mask][chosen])) chosen = v;
            if (chosen < 0 || dp[mask][chosen] >= INF) break;
            used[chosen] = true;
            for (int v = 0; v < n; ++v) if (present[chosen][v] && !used[v]) {
                const int64_t candidate = dp[mask][chosen] + weight[chosen][v];
                if (candidate < dp[mask][v]) dp[mask][v] = candidate;
            }
        }
    }
    int64_t answer = INF;
    for (int v = 0; v < n; ++v) if (dp[masks - 1][v] < answer) answer = dp[masks - 1][v];
    return answer >= INF ? -2 : answer;
}
