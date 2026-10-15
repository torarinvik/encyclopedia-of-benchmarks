/// Unrestricted Damerau-Levenshtein distance over ASCII byte strings.
#[no_mangle]
pub extern "C" fn damerau_levenshtein_distance(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > 66 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (left_n_value, right_n_value) = (values[0], values[1]);
    if !(0..=32).contains(&left_n_value) || !(0..=32).contains(&right_n_value) { return -1; }
    let (n, m) = (left_n_value as usize, right_n_value as usize);
    if length != 2 + n + m || values[2..].iter().any(|&b| !(0..=127).contains(&b)) { return -1; }
    let (left, right) = (&values[2..2+n], &values[2+n..]);
    let mut dp = [[0_i64; 34]; 34];
    let mut last = [0_usize; 128];
    let max_distance = (n + m) as i64;
    dp[0][0] = max_distance;
    for i in 0..=n { dp[i+1][0] = max_distance; dp[i+1][1] = i as i64; }
    for j in 0..=m { dp[0][j+1] = max_distance; dp[1][j+1] = j as i64; }
    for i in 1..=n {
        let mut last_match_column = 0;
        for j in 1..=m {
            let last_match_row = last[right[j-1] as usize];
            let prior_match_column = last_match_column;
            let cost = i64::from(left[i-1] != right[j-1]);
            if cost == 0 { last_match_column = j; }
            let transposition = dp[last_match_row][prior_match_column]
                + (i - last_match_row - 1) as i64 + 1 + (j - prior_match_column - 1) as i64;
            dp[i+1][j+1] = (dp[i][j] + cost)
                .min(dp[i+1][j] + 1).min(dp[i][j+1] + 1).min(transposition);
        }
        last[left[i-1] as usize] = i;
    }
    dp[n+1][m+1]
}
