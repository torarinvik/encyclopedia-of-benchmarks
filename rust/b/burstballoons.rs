const MAX_BALLOONS: usize = 128;

/// Maximum coins from bursting balloons by interval dynamic programming.
#[no_mangle]
pub unsafe extern "C" fn burstballoons(values: *const i64, length: usize) -> i64 {
    if length > MAX_BALLOONS || (length != 0 && values.is_null()) {
        return -1;
    }
    if length == 0 {
        return 0;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|&value| !(0..=1000).contains(&value)) {
        return -1;
    }

    let mut padded = [0i64; MAX_BALLOONS + 2];
    let mut dp = [[0i64; MAX_BALLOONS + 2]; MAX_BALLOONS + 2];
    padded[0] = 1;
    padded[length + 1] = 1;
    padded[1..=length].copy_from_slice(input);

    for span in 1..=length {
        for left in 1..=length - span + 1 {
            let right = left + span - 1;
            let mut best = 0i64;
            for last in left..=right {
                let coins = dp[left][last - 1]
                    + dp[last + 1][right]
                    + padded[left - 1] * padded[last] * padded[right + 1];
                best = best.max(coins);
            }
            dp[left][right] = best;
        }
    }
    dp[1][length]
}
