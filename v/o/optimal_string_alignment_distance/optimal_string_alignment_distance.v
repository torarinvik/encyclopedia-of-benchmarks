module optimal_string_alignment_distance

// Restricted Damerau-Levenshtein (optimal string alignment) distance.
@[export: 'optimal_string_alignment_distance']
pub fn optimal_string_alignment_distance(values &i64, length usize) i64 {
    if length < 2 || length > 66 { return -1 }
    unsafe {
        left_n_value := values[0]
        right_n_value := values[1]
        if left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32 { return -1 }
        n := usize(left_n_value)
        m := usize(right_n_value)
        if length != 2 + n + m { return -1 }
        for k := usize(0); k < n + m; k++ { if values[2 + k] < 0 || values[2 + k] > 127 { return -1 } }
        mut dp := [34][34]i64{}
        for i := usize(0); i <= n; i++ { dp[i][0] = i64(i) }
        for j := usize(0); j <= m; j++ { dp[0][j] = i64(j) }
        for i := usize(1); i <= n; i++ {
            for j := usize(1); j <= m; j++ {
                cost := if values[2 + i - 1] == values[2 + n + j - 1] { i64(0) } else { i64(1) }
                mut best := dp[i - 1][j - 1] + cost
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
}
