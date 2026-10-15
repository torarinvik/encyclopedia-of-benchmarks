#[no_mangle]
pub extern "C" fn unique_subsequences_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > 31 {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = packed[0];
    if !(0..=30).contains(&n_value) || length != n_value as usize + 1 {
        return -1;
    }
    let n = n_value as usize;
    if packed[1..].iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }
    let mut dp = [0i64; 31];
    for end in (1..=n).rev() {
        let i = end - 1;
        let mut seen = [false; 128];
        for j in i..n {
            let ch = packed[j + 1] as usize;
            if !seen[ch] {
                seen[ch] = true;
                dp[i] += 1 + dp[j + 1];
            }
        }
    }
    dp[0]
}
