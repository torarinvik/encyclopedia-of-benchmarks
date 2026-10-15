module damerau_levenshtein_distance;

// Unrestricted Damerau-Levenshtein distance over ASCII byte strings.
fn long damerau_levenshtein_distance(long* values, usz length) @export("damerau_levenshtein_distance")
{
    if (values == null || length < 2 || length > 66) return -1;
    long left_n_value = values[0], right_n_value = values[1];
    if (left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32) return -1;
    usz n = (usz)left_n_value, m = (usz)right_n_value;
    if (length != 2 + n + m) return -1;
    for (usz k = 0; k < n + m; k++) if (values[2 + k] < 0 || values[2 + k] > 127) return -1;

    long[34][34] dp;
    long[128] last;
    for (usz i = 0; i < 34; i++) for (usz j = 0; j < 34; j++) dp[i][j] = 0;
    for (usz k = 0; k < 128; k++) last[k] = 0;
    long max_distance = (long)(n + m);
    dp[0][0] = max_distance;
    for (usz i = 0; i <= n; i++) { dp[i + 1][0] = max_distance; dp[i + 1][1] = (long)i; }
    for (usz j = 0; j <= m; j++) { dp[0][j + 1] = max_distance; dp[1][j + 1] = (long)j; }
    for (usz i = 1; i <= n; i++) {
        usz last_match_column = 0;
        for (usz j = 1; j <= m; j++) {
            usz last_match_row = (usz)last[(usz)values[2 + n + j - 1]];
            usz prior_match_column = last_match_column;
            long cost = values[2 + i - 1] == values[2 + n + j - 1] ? 0 : 1;
            if (cost == 0) last_match_column = j;
            long best = dp[i][j] + cost;
            long insertion = dp[i + 1][j] + 1;
            long deletion = dp[i][j + 1] + 1;
            long transpose = dp[last_match_row][prior_match_column] + (long)(i - last_match_row - 1) + 1 + (long)(j - prior_match_column - 1);
            if (insertion < best) best = insertion;
            if (deletion < best) best = deletion;
            if (transpose < best) best = transpose;
            dp[i + 1][j + 1] = best;
        }
        last[(usz)values[2 + i - 1]] = (long)i;
    }
    return dp[n + 1][m + 1];
}
