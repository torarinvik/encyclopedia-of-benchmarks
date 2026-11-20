#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 3, MAX_N = 10, MAX_LENGTH = 37, MAX_WEIGHT = 1000 };

int64_t convex_polygon_minimum_weight_triangulation(const int64_t *input,
                                                    size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    size_t diagonal_count = 0;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 2; j < n; ++j) {
            if (!(i == 0 && j == n - 1)) ++diagonal_count;
        }
    }
    if (length != 1 + diagonal_count) return -1;

    int64_t weight[MAX_N][MAX_N] = {{0}};
    size_t at = 1;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 2; j < n; ++j) {
            if (i == 0 && j == n - 1) continue;
            if (input[at] < 0 || input[at] > MAX_WEIGHT) return -1;
            weight[i][j] = input[at++];
        }
    }

    int64_t dp[MAX_N][MAX_N] = {{0}};
    for (size_t span = 2; span < n; ++span) {
        for (size_t left = 0; left + span < n; ++left) {
            const size_t right = left + span;
            int64_t best = INT64_MAX;
            for (size_t split = left + 1; split < right; ++split) {
                const int64_t left_edge = split - left == 1 ? 0 : weight[left][split];
                const int64_t right_edge = right - split == 1 ? 0 : weight[split][right];
                const int64_t candidate = dp[left][split] + dp[split][right]
                                        + left_edge + right_edge;
                if (candidate < best) best = candidate;
            }
            dp[left][right] = best;
        }
    }
    return dp[0][n - 1];
}
