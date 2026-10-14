/// Return the length of a strictly increasing subsequence.
#[no_mangle]
pub extern "C" fn longest_increasing_subsequence(values: *const i64, length: usize) -> i64 {
    if length > 512 {
        return -1;
    }
    if length == 0 {
        return 0;
    }
    if values.is_null() {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut dp = [0i64; 512];
    let mut longest = 0i64;
    for index in 0..length {
        dp[index] = 1;
        for previous in 0..index {
            if values[index] > values[previous] && dp[index] < dp[previous] + 1 {
                dp[index] = dp[previous] + 1;
            }
        }
        longest = longest.max(dp[index]);
    }
    longest
}
