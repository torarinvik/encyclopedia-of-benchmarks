#include <stddef.h>
#include <stdint.h>
#include <limits.h>

enum { MAX_N = 64 };
int64_t knuth_optimized_optimal_binary_search_tree(const int64_t *v, size_t n) {
    if (v == NULL || n < 2 || n > 65 || v[0] < 1 || v[0] > MAX_N || n != (size_t)v[0] + 1) return -1;
    size_t k = (size_t)v[0];
    int64_t prefix[65] = {0}, dp[64][64] = {{0}};
    size_t opt[64][64] = {{0}};
    for (size_t i = 0; i < k; ++i) {
        int64_t f = v[i + 1];
        if (f < 0 || f > 1000000) return -1;
        prefix[i + 1] = prefix[i] + f; dp[i][i] = f; opt[i][i] = i;
    }
    for (size_t width = 2; width <= k; ++width) {
        for (size_t left = 0; left + width <= k; ++left) {
            size_t right = left + width - 1;
            size_t first = opt[left][right - 1], last = opt[left + 1][right];
            int64_t total = prefix[right + 1] - prefix[left], best = INT64_MAX;
            size_t best_root = first;
            for (size_t root = first; root <= last; ++root) {
                int64_t cost = total;
                if (root > left) cost += dp[left][root - 1];
                if (root < right) cost += dp[root + 1][right];
                if (cost < best) { best = cost; best_root = root; }
            }
            dp[left][right] = best; opt[left][right] = best_root;
        }
    }
    return dp[0][k - 1];
}
