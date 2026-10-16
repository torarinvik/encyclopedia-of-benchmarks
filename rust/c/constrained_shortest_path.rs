const INF: i64 = i64::MAX;

#[no_mangle]
pub unsafe extern "C" fn constrained_shortest_path(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 || length > 5 + 4 * 64 { return -2; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let m_raw = values[1];
    let start_raw = values[2];
    let target_raw = values[3];
    let limit_raw = values[4];
    if !(1..=16).contains(&n_raw) || !(0..=64).contains(&m_raw) || !(0..=32).contains(&limit_raw) { return -2; }
    let n = n_raw as usize;
    let m = m_raw as usize;
    let limit = limit_raw as usize;
    if length != 5+4*m || start_raw < 0 || start_raw >= n_raw || target_raw < 0 || target_raw >= n_raw { return -2; }
    for e in 0..m {
        let p = 5+4*e;
        if values[p] < 0 || values[p] >= n_raw || values[p+1] < 0 || values[p+1] >= n_raw ||
            !(0..=1000).contains(&values[p+2]) || !(1..=32).contains(&values[p+3]) { return -2; }
    }
    let mut dp = [[INF; 16]; 33];
    for r in 0..=limit { for u in 0..n { dp[r][u] = INF; } }
    dp[0][start_raw as usize] = 0;
    for r in 0..=limit {
        for u in 0..n {
            if dp[r][u] == INF { continue; }
            for e in 0..m {
                let p=5+4*e;
                if values[p] != u as i64 { continue; }
                let resource=values[p+3] as usize;
                if r+resource<=limit {
                    let v=values[p+1] as usize;
                    let candidate=dp[r][u]+values[p+2];
                    if candidate<dp[r+resource][v] { dp[r+resource][v]=candidate; }
                }
            }
        }
    }
    let mut answer=INF;
    for r in 0..=limit { answer=answer.min(dp[r][target_raw as usize]); }
    if answer==INF { -1 } else { answer }
}
