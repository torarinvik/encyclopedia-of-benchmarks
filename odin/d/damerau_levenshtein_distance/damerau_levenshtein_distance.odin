package damerau_levenshtein_distance

import "core:c"

// Unrestricted Damerau-Levenshtein distance over ASCII byte strings.
@(export)
damerau_levenshtein_distance :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 66 do return -1
    left_n_value := values[0]
    right_n_value := values[1]
    if left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32 do return -1
    n := c.size_t(left_n_value)
    m := c.size_t(right_n_value)
    if length != 2 + n + m do return -1
    for k: c.size_t = 0; k < n + m; k += 1 {
        if values[2 + k] < 0 || values[2 + k] > 127 do return -1
    }

    dp: [34][34]i64
    last: [128]c.size_t
    for i: c.size_t = 0; i < 34; i += 1 {
        for j: c.size_t = 0; j < 34; j += 1 { dp[i][j] = 0 }
    }
    for k: c.size_t = 0; k < 128; k += 1 { last[k] = 0 }
    max_distance := i64(n + m)
    dp[0][0] = max_distance
    for i: c.size_t = 0; i <= n; i += 1 { dp[i + 1][0] = max_distance; dp[i + 1][1] = i64(i) }
    for j: c.size_t = 0; j <= m; j += 1 { dp[0][j + 1] = max_distance; dp[1][j + 1] = i64(j) }
    for i: c.size_t = 1; i <= n; i += 1 {
        last_match_column := c.size_t(0)
        for j: c.size_t = 1; j <= m; j += 1 {
            last_match_row := last[c.size_t(values[2 + n + j - 1])]
            prior_match_column := last_match_column
            cost := i64(1)
            if values[2 + i - 1] == values[2 + n + j - 1] { cost = 0; last_match_column = j }
            best := dp[i][j] + cost
            insertion := dp[i + 1][j] + 1
            deletion := dp[i][j + 1] + 1
            transpose := dp[last_match_row][prior_match_column] + i64(i - last_match_row - 1) + 1 + i64(j - prior_match_column - 1)
            if insertion < best { best = insertion }
            if deletion < best { best = deletion }
            if transpose < best { best = transpose }
            dp[i + 1][j + 1] = best
        }
        last[c.size_t(values[2 + i - 1])] = i
    }
    return dp[n + 1][m + 1]
}
