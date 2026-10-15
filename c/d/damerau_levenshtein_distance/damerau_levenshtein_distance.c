/* Unrestricted Damerau-Levenshtein distance over ASCII byte strings. */
#include <stddef.h>
#include <stdint.h>

int64_t damerau_levenshtein_distance(const int64_t *values, size_t length)
{
    if (length < 2 || length > 66) return -1;
    const int64_t left_n_value = values[0], right_n_value = values[1];
    if (left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32) return -1;
    const size_t n = (size_t)left_n_value, m = (size_t)right_n_value;
    if (length != 2 + n + m) return -1;
    const int64_t *left = values + 2, *right = left + n;
    for (size_t k = 0; k < n + m; ++k) if (values[2 + k] < 0 || values[2 + k] > 127) return -1;

    int64_t dp[34][34] = {{0}}, last[128] = {0};
    const int64_t max_distance = (int64_t)(n + m);
    dp[0][0] = max_distance;
    for (size_t i = 0; i <= n; ++i) { dp[i + 1][0] = max_distance; dp[i + 1][1] = (int64_t)i; }
    for (size_t j = 0; j <= m; ++j) { dp[0][j + 1] = max_distance; dp[1][j + 1] = (int64_t)j; }
    for (size_t i = 1; i <= n; ++i) {
        size_t last_match_column = 0;
        for (size_t j = 1; j <= m; ++j) {
            const size_t last_match_row = (size_t)last[(size_t)right[j - 1]];
            const size_t prior_match_column = last_match_column;
            const int64_t cost = left[i - 1] == right[j - 1] ? 0 : 1;
            if (cost == 0) last_match_column = j;
            int64_t best = dp[i][j] + cost;
            const int64_t insertion = dp[i + 1][j] + 1;
            const int64_t deletion = dp[i][j + 1] + 1;
            const int64_t transpose = dp[last_match_row][prior_match_column] + (int64_t)(i - last_match_row - 1) + 1 + (int64_t)(j - prior_match_column - 1);
            if (insertion < best) best = insertion;
            if (deletion < best) best = deletion;
            if (transpose < best) best = transpose;
            dp[i + 1][j + 1] = best;
        }
        last[(size_t)left[i - 1]] = (int64_t)i;
    }
    return dp[n + 1][m + 1];
}
