module optimal_string_alignment_distance;

// Restricted Damerau-Levenshtein (optimal string alignment) distance.
fn long optimal_string_alignment_distance(long* values, usz length) @export("optimal_string_alignment_distance")
{
    if (values == null || length < 2 || length > 66) return -1;
    long left_n_value = values[0], right_n_value = values[1];
    if (left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32) return -1;
    usz n = (usz)left_n_value, m = (usz)right_n_value;
    if (length != 2 + n + m) return -1;
    for (usz k = 0; k < n + m; k++) if (values[2 + k] < 0 || values[2 + k] > 127) return -1;

    long[34][34] dp;
    for (usz i = 0; i < 34; i++) for (usz j = 0; j < 34; j++) dp[i][j] = 0;
    for (usz i = 0; i <= n; i++) dp[i][0] = (long)i;
    for (usz j = 0; j <= m; j++) dp[0][j] = (long)j;
    for (usz i = 1; i <= n; i++) {
        for (usz j = 1; j <= m; j++) {
            long cost = values[2 + i - 1] == values[2 + n + j - 1] ? 0 : 1;
            long best = dp[i - 1][j - 1] + cost;
            long insertion = dp[i][j - 1] + 1;
            long deletion = dp[i - 1][j] + 1;
            if (insertion < best) best = insertion;
            if (deletion < best) best = deletion;
            if (i > 1 && j > 1 && values[2 + i - 1] == values[2 + n + j - 2] && values[2 + i - 2] == values[2 + n + j - 1]) {
                long transpose = dp[i - 2][j - 2] + cost;
                if (transpose < best) best = transpose;
            }
            dp[i][j] = best;
        }
    }
    return dp[n][m];
}
