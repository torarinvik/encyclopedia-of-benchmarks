/* Independent bounded subset-assignment draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>

int64_t tree_sibling_distinct_cost_coloring(const int64_t *input, size_t length) {
    if (!input || length < 3 || length > 354) return -1;
    int64_t nr = input[0], kr = input[1];
    if (nr < 1 || nr > 32 || kr < 1 || kr > 10) return -1;
    int n = (int)nr, k = (int)kr;
    if (length != (size_t)(n + 1 + n * k)) return -1;
    for (int v = 1; v < n; ++v)
        if (input[1 + v] < 0 || input[1 + v] >= v) return -1;
    for (int i = 0; i < n * k; ++i)
        if (input[n + 1 + i] < 0 || input[n + 1 + i] > 1000000) return -1;

    const int64_t inf = INT64_C(1000000000000);
    int64_t dp[32][10], current[1024], next[1024];
    int states = 1 << k;
    for (int v = n - 1; v >= 0; --v) {
        for (int color = 0; color < k; ++color) {
            for (int mask = 0; mask < states; ++mask) current[mask] = inf;
            current[1 << color] = 0;
            for (int child = v + 1; child < n; ++child) {
                if (input[1 + child] != v) continue;
                for (int mask = 0; mask < states; ++mask) next[mask] = inf;
                for (int mask = 0; mask < states; ++mask) {
                    if (current[mask] == inf) continue;
                    for (int c = 0; c < k; ++c) {
                        if ((mask & (1 << c)) || dp[child][c] == inf) continue;
                        int extended = mask | (1 << c);
                        int64_t candidate = current[mask] + dp[child][c];
                        if (candidate < next[extended]) next[extended] = candidate;
                    }
                }
                for (int mask = 0; mask < states; ++mask) current[mask] = next[mask];
            }
            int64_t best = inf;
            for (int mask = 0; mask < states; ++mask)
                if (current[mask] < best) best = current[mask];
            dp[v][color] = best == inf ? inf : best + input[n + 1 + v * k + color];
        }
    }
    int64_t best = inf;
    for (int color = 0; color < k; ++color)
        if (dp[0][color] < best) best = dp[0][color];
    return best == inf ? -2 : best;
}
