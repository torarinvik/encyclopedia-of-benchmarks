const MAX_VALUES: usize = 128;

#[no_mangle]
pub unsafe extern "C" fn longest_palindromic_subsequence(values: *const i64, length: usize) -> i64 {
    if length > MAX_VALUES { return -1; }
    if length == 0 { return 0; }
    let mut dp = [0_i64; MAX_VALUES];
    let mut start = length;
    while start > 0 {
        start -= 1;
        dp[start] = 1;
        let mut diagonal = 0_i64;
        for finish in start + 1..length {
            let previous = dp[finish];
            if *values.add(start) == *values.add(finish) {
                dp[finish] = diagonal + 2;
            } else {
                dp[finish] = dp[finish].max(dp[finish - 1]);
            }
            diagonal = previous;
        }
    }
    dp[length - 1]
}
