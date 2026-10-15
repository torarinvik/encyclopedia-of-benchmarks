package optimal_string_alignment_distance

import "core:c"

// Restricted Damerau-Levenshtein (optimal string alignment) distance.
@(export)
optimal_string_alignment_distance :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 66 do return -1
    left_n_value := values[0]
    right_n_value := values[1]
    if left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32 do return -1
    n := c.size_t(left_n_value)
    m := c.size_t(right_n_value)
    if length != 2 + n + m do return -1
    for k: c.size_t = 0; k < n + m; k += 1 { if values[2 + k] < 0 || values[2 + k] > 127 do return -1 }
    dp: [34][34]i64
    for i: c.size_t = 0; i <= n; i += 1 { dp[i][0] = i64(i) }
    for j: c.size_t = 0; j <= m; j += 1 { dp[0][j] = i64(j) }
    for i: c.size_t = 1; i <= n; i += 1 {
        for j: c.size_t = 1; j <= m; j += 1 {
            cost := i64(1)
            if values[2 + i - 1] == values[2 + n + j - 1] { cost = 0 }
            best := dp[i - 1][j - 1] + cost
            insertion := dp[i][j - 1] + 1
            deletion := dp[i - 1][j] + 1
            if insertion < best { best = insertion }
            if deletion < best { best = deletion }
            if i > 1 && j > 1 && values[2 + i - 1] == values[2 + n + j - 2] && values[2 + i - 2] == values[2 + n + j - 1] {
                transpose := dp[i - 2][j - 2] + cost
                if transpose < best { best = transpose }
            }
            dp[i][j] = best
        }
    }
    return dp[n][m]
}
