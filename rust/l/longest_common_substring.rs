const MAX_LENGTH: usize = 256;
#[no_mangle]
pub unsafe extern "C" fn longest_common_substring(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 2 { return -1; }
    let input = std::slice::from_raw_parts(raw, length);
    if input[0] < 0 || input[0] > MAX_LENGTH as i64 { return -1; }
    let first_length = input[0] as usize;
    if first_length + 2 > length || input[first_length + 1] < 0 || input[first_length + 1] > MAX_LENGTH as i64 { return -1; }
    let second_length = input[first_length + 1] as usize;
    if length != first_length + second_length + 2 { return -1; }
    let first = &input[1..1 + first_length];
    let second = &input[first_length + 2..];
    if first.iter().chain(second).any(|v| !(32..=126).contains(v)) { return -1; }
    let mut dp = [0i64; MAX_LENGTH + 1];
    let mut best = 0i64;
    for i in 1..=first_length {
        for j in (1..=second_length).rev() {
            if first[i - 1] == second[j - 1] { dp[j] = dp[j - 1] + 1; best = best.max(dp[j]); }
            else { dp[j] = 0; }
        }
    }
    best
}
