const MAX_N: usize = 64;
const MAX_INPUT: usize = 65;
const MAX_FREQUENCY: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn knuth_optimized_optimal_binary_search_tree(
    values: *const i64, length: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    let nv = v[0];
    if !(1..=MAX_N as i64).contains(&nv) || length != nv as usize + 1 { return -1; }
    let n = nv as usize;
    let mut prefix = [0i64; MAX_N + 1];
    let mut dp = [[0i64; MAX_N]; MAX_N];
    let mut opt = [[0usize; MAX_N]; MAX_N];
    for i in 0..n {
        let f = v[i + 1];
        if !(0..=MAX_FREQUENCY).contains(&f) { return -1; }
        prefix[i + 1] = prefix[i] + f;
        dp[i][i] = f;
        opt[i][i] = i;
    }
    for width in 2..=n {
        for left in 0..=n - width {
            let right = left + width - 1;
            let first = opt[left][right - 1];
            let last = opt[left + 1][right];
            let total = prefix[right + 1] - prefix[left];
            let mut best = i64::MAX;
            let mut best_root = first;
            for root in first..=last {
                let mut cost = total;
                if root > left { cost += dp[left][root - 1]; }
                if root < right { cost += dp[root + 1][right]; }
                if cost < best { best = cost; best_root = root; }
            }
            dp[left][right] = best;
            opt[left][right] = best_root;
        }
    }
    dp[0][n - 1]
}
