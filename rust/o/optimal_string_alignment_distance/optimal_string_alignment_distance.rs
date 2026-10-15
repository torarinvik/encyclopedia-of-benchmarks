/// Restricted Damerau-Levenshtein (optimal string alignment) distance.
#[no_mangle]
pub extern "C" fn optimal_string_alignment_distance(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > 66 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (left_n_value, right_n_value) = (values[0], values[1]);
    if !(0..=32).contains(&left_n_value) || !(0..=32).contains(&right_n_value) { return -1; }
    let (n, m) = (left_n_value as usize, right_n_value as usize);
    if length != 2 + n + m || values[2..].iter().any(|&b| !(0..=127).contains(&b)) { return -1; }
    let (left, right) = (&values[2..2+n], &values[2+n..]);
    let mut dp = [[0_i64; 34]; 34];
    for i in 0..=n { dp[i][0] = i as i64; }
    for j in 0..=m { dp[0][j] = j as i64; }
    for i in 1..=n {
        for j in 1..=m {
            let cost = i64::from(left[i-1] != right[j-1]);
            let mut best = (dp[i-1][j-1] + cost).min(dp[i][j-1] + 1).min(dp[i-1][j] + 1);
            if i > 1 && j > 1 && left[i-1] == right[j-2] && left[i-2] == right[j-1] {
                best = best.min(dp[i-2][j-2] + cost);
            }
            dp[i][j] = best;
        }
    }
    dp[n][m]
}
