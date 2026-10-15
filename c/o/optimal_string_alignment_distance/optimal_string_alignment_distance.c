/* Restricted Damerau-Levenshtein (optimal string alignment) distance. */
#include <stddef.h>
#include <stdint.h>

int64_t optimal_string_alignment_distance(const int64_t *values, size_t length)
{
    if (length < 2 || length > 66) return -1;
    const int64_t left_n_value = values[0], right_n_value = values[1];
    if (left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32) return -1;
    const size_t n = (size_t)left_n_value, m = (size_t)right_n_value;
    if (length != 2 + n + m) return -1;
    for (size_t k = 0; k < n + m; ++k) if (values[2 + k] < 0 || values[2 + k] > 127) return -1;
    const int64_t *left = values + 2, *right = left + n;
    int64_t dp[34][34] = {{0}};
    for (size_t i = 0; i <= n; ++i) dp[i][0] = (int64_t)i;
    for (size_t j = 0; j <= m; ++j) dp[0][j] = (int64_t)j;
    for (size_t i = 1; i <= n; ++i) {
        for (size_t j = 1; j <= m; ++j) {
            const int64_t cost = left[i - 1] == right[j - 1] ? 0 : 1;
            int64_t best = dp[i - 1][j - 1] + cost;
            if (dp[i][j - 1] + 1 < best) best = dp[i][j - 1] + 1;
            if (dp[i - 1][j] + 1 < best) best = dp[i - 1][j] + 1;
            if (i > 1 && j > 1 && left[i - 1] == right[j - 2] && left[i - 2] == right[j - 1] && dp[i - 2][j - 2] + cost < best)
                best = dp[i - 2][j - 2] + cost;
            dp[i][j] = best;
        }
    }
    return dp[n][m];
}
