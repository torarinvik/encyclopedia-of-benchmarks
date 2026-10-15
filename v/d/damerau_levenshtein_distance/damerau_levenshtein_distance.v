module damerau_levenshtein_distance

// Unrestricted Damerau-Levenshtein distance over ASCII byte strings.
@[export: 'damerau_levenshtein_distance']
pub fn damerau_levenshtein_distance(values &i64, length usize) i64 {
    if length < 2 || length > 66 { return -1 }
    unsafe {
        left_n_value := values[0]
        right_n_value := values[1]
        if left_n_value < 0 || left_n_value > 32 || right_n_value < 0 || right_n_value > 32 { return -1 }
        n := usize(left_n_value)
        m := usize(right_n_value)
        if length != 2 + n + m { return -1 }
        for k := usize(0); k < n + m; k++ {
            if values[2 + k] < 0 || values[2 + k] > 127 { return -1 }
        }
        mut dp := [34][34]i64{}
        mut last := [128]usize{}
        max_distance := i64(n + m)
        dp[0][0] = max_distance
        for i := usize(0); i <= n; i++ { dp[i + 1][0] = max_distance; dp[i + 1][1] = i64(i) }
        for j := usize(0); j <= m; j++ { dp[0][j + 1] = max_distance; dp[1][j + 1] = i64(j) }
        for i := usize(1); i <= n; i++ {
            mut last_match_column := usize(0)
            for j := usize(1); j <= m; j++ {
                last_match_row := last[usize(values[2 + n + j - 1])]
                prior_match_column := last_match_column
                mut cost := i64(1)
                if values[2 + i - 1] == values[2 + n + j - 1] { cost = 0; last_match_column = j }
                mut best := dp[i][j] + cost
                insertion := dp[i + 1][j] + 1
                deletion := dp[i][j + 1] + 1
                transposition := dp[last_match_row][prior_match_column] + i64(i - last_match_row - 1) + 1 + i64(j - prior_match_column - 1)
                if insertion < best { best = insertion }
                if deletion < best { best = deletion }
                if transposition < best { best = transposition }
                dp[i + 1][j + 1] = best
            }
            last[usize(values[2 + i - 1])] = i
        }
        return dp[n + 1][m + 1]
    }
}
